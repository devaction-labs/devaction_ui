defmodule DevactionUI.Slider do
  @moduledoc """
  A slider for a value inside a range, and a range slider for two (a from and a to). Both are native
  `<input type="range">`, so the keyboard (arrows, Home, End, Page keys) and assistive technology work as the
  browser does them; the look is the canvas's. The value is shown beside the track and is the LiveView's, sent
  by the form's `phx-change`. Values, limits and step are numbers: integers or floats.

  The range slider is two inputs on one track: the low one can never go above the high one and the other way
  round. The `DevactionUI.RangePair` hook enforces it in the browser while a thumb is dragged, painting the
  filled part and the value as it goes, and `range/3` enforces it on the server too. Give `format_text` (such as
  `"R$ %{value}k"`) instead of `format` and the value beside the label also follows the thumb between round
  trips; a `format` function can only run on the server.

  `bubble` puts the value in a small dark label over the thumb (beside it when vertical) that shows on hover,
  focus and while dragging and follows the thumb. It is `aria-hidden`: assistive technology already reads the
  value (or `value_text`) from the input. With `format_text` the bubble keeps the format between round trips.

  `orientation={:vertical}` stands the track up, with the value on top and the label below, and `aria-orientation`
  says so; the keys are the browser's (Up and Right raise the value, Down and Left lower it). Its height is
  `length_class` (default `h-40`). Marks (`ticks`) are for the horizontal slider only.
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
  attr :value, :any, required: true, doc: "a number"
  attr :label, :string, required: true
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :format, :any, default: nil, doc: "number to text, for the value beside the label"

  attr :format_text, :string,
    default: nil,
    doc: "the same as a text with `%{value}`; the browser fills it while the thumb moves"

  attr :value_text, :string,
    default: nil,
    doc: "what assistive technology reads in place of the number, such as \"Detailed\""

  attr :ticks, :list,
    default: [],
    doc:
      "names under the track in equal columns, first at the minimum and last at the maximum; the one the value is nearest to is stressed"

  attr :bubble, :boolean,
    default: false,
    doc: "the value in a small label over the thumb, while it is hovered, focused or dragged"

  attr :orientation, :atom, values: [:horizontal, :vertical], default: :horizontal

  attr :length_class, :string,
    default: "h-40",
    doc: "the height of a vertical track, as a class"

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global

  def slider(assigns) do
    assigns =
      assign(assigns,
        percent: percent(assigns.value, assigns.min, assigns.max),
        fraction: fraction(assigns.value, assigns.min, assigns.max)
      )

    ~H"""
    <div data-slider class={[root_class(@orientation), @class]} {@rest}>
      <span class={head_class(@orientation)}>
        <label for={@id} {label_attrs(@orientation)}>{@label}</label>
        <output
          for={@id}
          class={["font-mono text-[13px] font-normal text-ink-2", value_class(@orientation)]}
        >
          {text(@format, @format_text, @value)}
        </output>
      </span>
      <div class={["group/slider", field_class(@orientation, @length_class)]}>
        <input
          id={@id}
          name={@name}
          type="range"
          min={@min}
          max={@max}
          step={@step}
          value={@value}
          disabled={@disabled}
          aria-valuetext={@value_text}
          aria-orientation={@orientation == :vertical && "vertical"}
          phx-hook="DevactionUI.Range"
          data-format-text={@format_text}
          style={"--p: #{@percent}%"}
          class={["range", @orientation == :vertical && "range-vertical"]}
        />
        <.bubble
          :if={@bubble}
          orientation={@orientation}
          fraction={@fraction}
          text={text(@format, @format_text, @value)}
        />
      </div>
      <.tick_row :if={@ticks != [] and @orientation == :horizontal} ticks={@ticks} percent={@percent} />
    </div>
    """
  end

  attr :orientation, :atom, required: true
  attr :fraction, :float, required: true
  attr :text, :string, required: true
  attr :rest, :global

  defp bubble(assigns) do
    ~H"""
    <span
      data-bubble
      aria-hidden="true"
      class={["slider-bubble", @orientation == :vertical && "slider-bubble-vertical"]}
      style={"--f: #{@fraction}"}
      {@rest}
    >
      {@text}
    </span>
    """
  end

  defp root_class(:horizontal), do: "flex flex-col gap-2.5"
  defp root_class(:vertical), do: "flex w-fit min-w-10 flex-col items-center gap-2.5"

  defp head_class(:horizontal),
    do: "flex items-baseline justify-between gap-3 text-sm font-medium text-ink"

  defp head_class(:vertical), do: "contents text-sm font-medium text-ink"

  defp label_attrs(:horizontal), do: []
  defp label_attrs(:vertical), do: [class: "order-last text-center text-sm font-medium text-ink"]

  defp value_class(:horizontal), do: nil
  defp value_class(:vertical), do: "order-first"

  defp field_class(:horizontal, _length), do: "relative"
  defp field_class(:vertical, length), do: ["relative w-6", length]

  attr :ticks, :list, required: true
  attr :percent, :float, required: true

  defp tick_row(assigns) do
    assigns = assign(assigns, :active, active_tick(assigns.percent, length(assigns.ticks)))

    ~H"""
    <span
      class="grid text-xs text-muted"
      style={"grid-template-columns: repeat(#{length(@ticks)}, minmax(0, 1fr))"}
      aria-hidden="true"
    >
      <span
        :for={{tick, index} <- Enum.with_index(@ticks)}
        data-active={index == @active && "true"}
        class={[
          "data-[active=true]:font-medium data-[active=true]:text-ink",
          tick_align(index, length(@ticks))
        ]}
      >
        {tick}
      </span>
    </span>
    """
  end

  defp tick_align(0, _count), do: "text-left"
  defp tick_align(index, count) when index == count - 1, do: "text-right"
  defp tick_align(_index, _count), do: "text-center"

  @doc "The index of the mark nearest to a position of 0 to 100 on the track."
  @spec active_tick(number(), pos_integer()) :: non_neg_integer()
  def active_tick(_percent, 1), do: 0
  def active_tick(percent, count), do: round(percent / 100 * (count - 1))

  @doc "Where `value` sits between `min` and `max`, from 0 to 100."
  @spec percent(number(), number(), number()) :: float()
  def percent(_value, min, max) when max <= min, do: 0.0
  def percent(value, min, max), do: Float.round((value - min) / (max - min) * 100, 2)

  @doc "Where `value` sits between `min` and `max`, from 0 to 1."
  @spec fraction(number(), number(), number()) :: float()
  def fraction(value, min, max), do: Float.round(percent(value, min, max) / 100, 4)

  attr :id, :string, required: true
  attr :name_low, :string, required: true
  attr :name_high, :string, required: true
  attr :low, :any, required: true, doc: "a number"
  attr :high, :any, required: true, doc: "a number"
  attr :label, :string, default: nil, doc: "what the range is for, written above the track"
  attr :label_low, :string, required: true, doc: "names the low thumb for assistive technology"
  attr :label_high, :string, required: true, doc: "names the high thumb for assistive technology"
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :format, :any, default: nil
  attr :format_text, :string, default: nil, doc: "as in `slider/1`, for each of the two values"
  attr :bubble, :boolean, default: false, doc: "a value label over each thumb, as in `slider/1`"
  attr :orientation, :atom, values: [:horizontal, :vertical], default: :horizontal

  attr :length_class, :string,
    default: "h-40",
    doc: "the height of a vertical track, as a class"

  attr :class, :any, default: nil

  attr :rest, :global

  def range_slider(assigns) do
    from = percent(assigns.low, assigns.min, assigns.max)
    to = percent(assigns.high, assigns.min, assigns.max)

    assigns =
      assign(assigns,
        from: from,
        width: Float.round(to - from, 2),
        low_fraction: fraction(assigns.low, assigns.min, assigns.max),
        high_fraction: fraction(assigns.high, assigns.min, assigns.max)
      )

    ~H"""
    <div class={[root_class(@orientation), @class]} {@rest}>
      <span class={head_class(@orientation)}>
        <span id={"#{@id}-label"} {label_attrs(@orientation)}>{@label}</span>
        <output
          id={"#{@id}-output"}
          for={"#{@id}-low #{@id}-high"}
          class={[
            "font-mono text-[13px] font-normal whitespace-nowrap text-ink-2",
            value_class(@orientation)
          ]}
        >
          {text(@format, @format_text, @low)} – {text(@format, @format_text, @high)}
        </output>
      </span>
      <div
        id={@id}
        phx-hook="DevactionUI.RangePair"
        data-format-text={@format_text}
        data-orientation={@orientation}
        class={["group/slider", pair_class(@orientation, @length_class)]}
        role="group"
        aria-labelledby={"#{@id}-label"}
      >
        <span class={["absolute rounded-full bg-line", track_class(@orientation)]} aria-hidden="true" />
        <span
          data-fill
          class={["absolute rounded-full bg-ink", track_class(@orientation)]}
          style={fill_style(@orientation, @from, @width)}
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
          aria-orientation={@orientation == :vertical && "vertical"}
          data-low
          class={["range-thumb", @orientation == :vertical && "range-vertical"]}
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
          aria-orientation={@orientation == :vertical && "vertical"}
          data-high
          class={["range-thumb", @orientation == :vertical && "range-vertical"]}
        />
        <.bubble
          :if={@bubble}
          data-bubble-low
          orientation={@orientation}
          fraction={@low_fraction}
          text={text(@format, @format_text, @low)}
        />
        <.bubble
          :if={@bubble}
          data-bubble-high
          orientation={@orientation}
          fraction={@high_fraction}
          text={text(@format, @format_text, @high)}
        />
      </div>
    </div>
    """
  end

  defp pair_class(:horizontal, _length), do: "relative h-6"
  defp pair_class(:vertical, length), do: ["relative w-6", length]

  defp track_class(:horizontal), do: "top-1/2 h-1.5 w-full -translate-y-1/2"
  defp track_class(:vertical), do: "left-1/2 h-full w-1.5 -translate-x-1/2"

  defp fill_style(:horizontal, from, width), do: "left: #{from}%; width: #{width}%"
  defp fill_style(:vertical, from, width), do: "bottom: #{from}%; height: #{width}%"

  defp text(nil, nil, value), do: to_string(value)
  defp text(nil, pattern, value), do: String.replace(pattern, "%{value}", to_string(value))
  defp text(format, _pattern, value), do: format.(value)
end
