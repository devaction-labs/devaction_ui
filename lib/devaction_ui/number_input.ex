defmodule DevactionUI.NumberInput do
  @moduledoc """
  A number field with a minus and a plus, for a quantity that is changed a step at a time (hours, seats, days):
  the buttons are disabled at the limits, the field is a `spinbutton` that says its value and its limits, and
  typing in it works as well. The LiveView keeps the value: it learns of a press in `event` (with `phx-value-step`
  `-1` or `1`) and of typing in the field's own `phx-change`.

  `step/4` and `clamp/3` are the arithmetic, so the server applies the same rule the buttons suggest.
  """
  use Phoenix.Component

  @doc "`value` moved by `direction` (`-1` or `1`) steps, and kept inside `min` and `max`."
  @spec step(number(), number(), number() | nil, number() | nil) :: number()
  def step(value, delta, min, max), do: clamp(value + delta, min, max)

  @doc "`value` inside `min` and `max`; a limit that is `nil` does not apply."
  @spec clamp(number(), number() | nil, number() | nil) :: number()
  def clamp(value, min, max) do
    value |> at_least(min) |> at_most(max)
  end

  defp at_least(value, nil), do: value
  defp at_least(value, min), do: max(value, min)
  defp at_most(value, nil), do: value
  defp at_most(value, max), do: min(value, max)

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :integer, required: true
  attr :label, :string, required: true, doc: "what is counted, for assistive technology"
  attr :min, :integer, default: nil
  attr :max, :integer, default: nil
  attr :step, :integer, default: 1
  attr :event, :string, required: true, doc: "sent by the buttons, with `phx-value-step`"
  attr :decrease_label, :string, required: true
  attr :increase_label, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  slot :minus_icon, required: true
  slot :plus_icon, required: true

  attr :rest, :global

  def number_input(assigns) do
    ~H"""
    <div id={@id} class={["number-input", @disabled && "opacity-60", @class]} {@rest}>
      <button
        id={"#{@id}-minus"}
        type="button"
        aria-label={@decrease_label}
        aria-controls={"#{@id}-field"}
        disabled={@disabled or (@min != nil and @value <= @min)}
        phx-click={@event}
        phx-value-step={-@step}
        class="grid place-items-center outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-40"
      >
        {render_slot(@minus_icon)}
      </button>
      <input
        id={"#{@id}-field"}
        name={@name}
        type="text"
        inputmode="numeric"
        role="spinbutton"
        aria-label={@label}
        aria-valuenow={@value}
        aria-valuemin={@min}
        aria-valuemax={@max}
        value={@value}
        disabled={@disabled}
        class="min-w-0 border-0 bg-transparent px-2 font-mono text-[15px] tabular-nums outline-none focus:ring-0"
      />
      <button
        id={"#{@id}-plus"}
        type="button"
        aria-label={@increase_label}
        aria-controls={"#{@id}-field"}
        disabled={@disabled or (@max != nil and @value >= @max)}
        phx-click={@event}
        phx-value-step={@step}
        class="grid place-items-center outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-40"
      >
        {render_slot(@plus_icon)}
      </button>
    </div>
    """
  end
end
