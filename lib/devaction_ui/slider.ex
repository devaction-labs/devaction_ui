defmodule DevactionUI.Slider do
  @moduledoc """
  A slider for a value inside a range, and a range slider for two (a from and a to). Both are native
  `<input type="range">`, so the keyboard (arrows, Home, End, Page keys) and assistive technology work as the
  browser does them; the look is the canvas's. The value is shown beside the track and is the LiveView's, sent
  by the form's `phx-change`.

  The range slider is two inputs on one track: the low one can never go above the high one and the other way
  round, which `range/3` enforces on the server too.
  """
  use Phoenix.Component

  @doc "A pair `{low, high}` put in order and inside `min` and `max`."
  @spec range(number(), number(), {number(), number()}) :: {number(), number()}
  def range(min, max, {a, b}) do
    {low, high} = Enum.min_max([a, b])
    {max(low, min), min(high, max)}
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :integer, required: true
  attr :label, :string, required: true
  attr :min, :integer, default: 0
  attr :max, :integer, default: 100
  attr :step, :integer, default: 1
  attr :format, :any, default: nil, doc: "number to text, for the value beside the label"

  attr :ticks, :list,
    default: [],
    doc: "names under the track, first at the minimum and last at the maximum"

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global

  def slider(assigns) do
    assigns = assign(assigns, :percent, percent(assigns.value, assigns.min, assigns.max))

    ~H"""
    <div class={["flex flex-col gap-2.5", @class]} {@rest}>
      <span class="flex items-baseline justify-between gap-3 text-sm font-medium text-ink">
        <label for={@id}>{@label}</label>
        <output for={@id} class="font-mono text-[13px] font-normal">{text(@format, @value)}</output>
      </span>
      <input
        id={@id}
        name={@name}
        type="range"
        min={@min}
        max={@max}
        step={@step}
        value={@value}
        disabled={@disabled}
        phx-hook="DevactionUI.Range"
        style={"--p: #{@percent}%"}
        class="range"
      />
      <span :if={@ticks != []} class="flex justify-between text-xs text-muted" aria-hidden="true">
        <span :for={tick <- @ticks}>{tick}</span>
      </span>
    </div>
    """
  end

  @doc "Where `value` sits between `min` and `max`, from 0 to 100."
  @spec percent(number(), number(), number()) :: float()
  def percent(_value, min, max) when max <= min, do: 0.0
  def percent(value, min, max), do: Float.round((value - min) / (max - min) * 100, 2)

  attr :id, :string, required: true
  attr :name_low, :string, required: true
  attr :name_high, :string, required: true
  attr :low, :integer, required: true
  attr :high, :integer, required: true
  attr :label, :string, default: nil, doc: "what the range is for, written above the track"
  attr :label_low, :string, required: true, doc: "names the low thumb for assistive technology"
  attr :label_high, :string, required: true, doc: "names the high thumb for assistive technology"
  attr :min, :integer, default: 0
  attr :max, :integer, default: 100
  attr :step, :integer, default: 1
  attr :format, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global

  def range_slider(assigns) do
    span = max(assigns.max - assigns.min, 1)

    assigns =
      assign(assigns,
        from: Float.round((assigns.low - assigns.min) / span * 100, 2),
        to: Float.round((assigns.high - assigns.min) / span * 100, 2)
      )

    ~H"""
    <div class={["flex flex-col gap-2.5", @class]} {@rest}>
      <span class="flex items-baseline justify-between gap-3 text-sm font-medium text-ink">
        <span id={"#{@id}-label"}>{@label}</span>
        <output
          for={"#{@id}-low #{@id}-high"}
          class="font-mono text-[13px] font-normal whitespace-nowrap"
        >
          {text(@format, @low)} – {text(@format, @high)}
        </output>
      </span>
      <div id={@id} class="range-pair relative h-6" role="group" aria-labelledby={"#{@id}-label"}>
        <span
          class="absolute top-1/2 h-1.5 w-full -translate-y-1/2 rounded-full bg-line"
          aria-hidden="true"
        />
        <span
          class="absolute top-1/2 h-1.5 -translate-y-1/2 rounded-full bg-ink"
          style={"left: #{@from}%; width: #{@to - @from}%"}
          aria-hidden="true"
        />
        <input
          id={"#{@id}-low"}
          name={@name_low}
          type="range"
          min={@min}
          max={@max}
          step={@step}
          value={@low}
          aria-label={@label_low}
          class="range-thumb"
        />
        <input
          id={"#{@id}-high"}
          name={@name_high}
          type="range"
          min={@min}
          max={@max}
          step={@step}
          value={@high}
          aria-label={@label_high}
          class="range-thumb"
        />
      </div>
    </div>
    """
  end

  defp text(nil, value), do: to_string(value)
  defp text(format, value), do: format.(value)
end
