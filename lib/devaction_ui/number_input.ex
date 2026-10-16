defmodule DevactionUI.NumberInput do
  @moduledoc """
  A number field with a minus and a plus, for a whole quantity that is changed a step at a time (hours, seats,
  days): the buttons are disabled at the limits, the field is a `spinbutton` that says its value (and its `unit`)
  and its limits, and typing in it works as well. Only integers: the arrows, `PageUp` and `PageDown` (ten steps)
  are the hook `DevactionUI.NumberInput`, and what is typed is held inside `min` and `max` when the field is left.

  The LiveView keeps the value: it learns of a press, or of an arrow key, in `event` (with `phx-value-step`, the
  signed amount to move), and of typing in the field's own `phx-change`. `step/4` and `clamp/3` are the arithmetic,
  so the server applies the same rule the buttons suggest:

      def handle_event("seats_step", %{"step" => step}, socket) do
        seats = NumberInput.step(socket.assigns.seats, String.to_integer(step), 1, 30)
        {:noreply, assign(socket, :seats, seats)}
      end

      def handle_event("validate", %{"seats" => text}, socket) do
        seats =
          case Integer.parse(text) do
            {n, ""} -> NumberInput.clamp(n, 1, 30)
            _ -> socket.assigns.seats
          end

        {:noreply, assign(socket, :seats, seats)}
      end

  The label and the `help` text (`Between 1 and 30`) are described to assistive technology; the words of the
  buttons are the caller's (`decrease_label`, `increase_label`).
  """
  use Phoenix.Component

  @doc "`value` moved by `delta`, and kept inside `min` and `max`."
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
  attr :unit, :string, default: nil, doc: "shown beside the value and read with it: `h`, `seats`"
  attr :min, :integer, default: nil
  attr :max, :integer, default: nil
  attr :step, :integer, default: 1

  attr :event, :string,
    required: true,
    doc: "sent by the buttons and the arrow keys, with `phx-value-step`"

  attr :decrease_label, :string, required: true
  attr :increase_label, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  slot :minus_icon, required: true
  slot :plus_icon, required: true
  slot :help, doc: "a line under the field, e.g. `Between 1 and 30`"

  attr :rest, :global

  def number_input(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.NumberInput"
      data-event={@event}
      data-step={@step}
      data-min={@min}
      data-max={@max}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <div class={["number-input", @disabled && "opacity-60"]}>
        <button
          id={"#{@id}-minus"}
          type="button"
          aria-label={@decrease_label}
          aria-controls={"#{@id}-field"}
          disabled={@disabled or (@min != nil and @value <= @min)}
          phx-click={@event}
          phx-value-step={-@step}
          class="grid place-items-center text-lg outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:text-done-cell"
        >
          {render_slot(@minus_icon)}
        </button>
        <span class="flex flex-1 items-baseline justify-center gap-1.5">
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
            aria-valuetext={@unit && "#{@value} #{@unit}"}
            aria-describedby={@help != [] && "#{@id}-help"}
            value={@value}
            disabled={@disabled}
            class="min-w-[2ch] border-0 bg-transparent p-0 text-center font-sans text-[17px] font-medium tabular-nums outline-none [field-sizing:content] focus:ring-0"
          />
          <span :if={@unit} class="text-[13px] text-muted">{@unit}</span>
        </span>
        <button
          id={"#{@id}-plus"}
          type="button"
          aria-label={@increase_label}
          aria-controls={"#{@id}-field"}
          disabled={@disabled or (@max != nil and @value >= @max)}
          phx-click={@event}
          phx-value-step={@step}
          class="grid place-items-center text-lg outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:text-done-cell"
        >
          {render_slot(@plus_icon)}
        </button>
      </div>
      <p :if={@help != []} id={"#{@id}-help"} class="m-0 text-xs text-muted">{render_slot(@help)}</p>
    </div>
    """
  end
end
