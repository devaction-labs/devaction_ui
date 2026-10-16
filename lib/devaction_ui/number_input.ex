defmodule DevactionUI.NumberInput do
  @moduledoc """
  A number field with a minus and a plus, for a quantity that is changed a step at a time (hours, seats, a rate):
  the buttons are disabled at the limits, the field is a `spinbutton` that says its value (and its `unit`) and its
  limits, and typing in it works as well. The arrows, `PageUp` and `PageDown` (ten steps), `Home` and `End` (the
  limits) are the hook `DevactionUI.NumberInput`, and what is typed is held inside `min` and `max` when the field
  is left.

  The numbers are whole or decimal, as a number or as text (`1`, `0.25`, `"0.25"`, `"0,25"`): a fractional `step`
  is fine, and `precision` is how many decimals the field shows (it defaults to the decimals of `step` and of the
  value). The arithmetic is done on integers scaled by a power of ten, so `0.1 + 0.2` is `0.3` and a step never
  drifts, in `step/4` and `clamp/3` on the server and in the hook in the browser. `decimal` is the separator the
  field shows and reads (`","` for pt-BR); the wire (`phx-value-step`, `aria-valuenow`, `data-*`) always uses a dot.

  The LiveView keeps the value: it learns of a press, or of a key, in `event` (with `phx-value-step`, the signed
  amount to move, as text), and of typing in the field's own `phx-change`. `step/4`, `clamp/3` and `parse/1` are
  the arithmetic, so the server applies the same rule the buttons suggest:

      def handle_event("seats_step", %{"step" => step}, socket) do
        seats = NumberInput.step(socket.assigns.seats, step, 1, 30)
        {:noreply, assign(socket, :seats, seats)}
      end

      def handle_event("validate", %{"seats" => text}, socket) do
        seats =
          case NumberInput.parse(text) do
            {:ok, n} -> NumberInput.clamp(n, 1, 30)
            :error -> socket.assigns.seats
          end

        {:noreply, assign(socket, :seats, seats)}
      end

  The label and the `help` text (`Between 1 and 30`) are described to assistive technology; the words of the
  buttons are the caller's (`decrease_label`, `increase_label`). The `unit` is text read with the value; a `unit_mark`
  slot only changes how it is drawn (`m<sup>2</sup>`).
  """
  use Phoenix.Component

  @number ~r/^\s*(?<sign>[+-]?)(?<whole>\d+)(?:[.,](?<frac>\d+))?(?:[eE](?<exp>[+-]?\d{1,3}))?\s*$/

  @typedoc "A number, or text that reads as one (`0.25`, or `0,25` between quotes); a `Decimal` works too."
  @type amount :: number() | String.t()

  @doc """
  `value` moved by `delta`, and kept inside `min` and `max`. The sum is exact: the result is an integer when it
  is whole and the nearest float otherwise.

      iex> DevactionUI.NumberInput.step(0.1, 0.2, nil, nil)
      0.3
      iex> DevactionUI.NumberInput.step("2.5", "-1", 1, 5)
      1.5
  """
  @spec step(amount(), amount(), amount() | nil, amount() | nil) :: number()
  def step(value, delta, min, max),
    do: value |> scaled!() |> add(scaled!(delta)) |> held(min, max) |> number()

  @doc "`value` inside `min` and `max`; a limit that is `nil` does not apply."
  @spec clamp(amount(), amount() | nil, amount() | nil) :: number()
  def clamp(value, min, max), do: value |> scaled!() |> held(min, max) |> number()

  @doc """
  The number a typed text says, with a dot or a comma as the decimal separator; `:error` when it is not one.

      iex> DevactionUI.NumberInput.parse("1,5")
      {:ok, 1.5}
      iex> DevactionUI.NumberInput.parse("abc")
      :error
  """
  @spec parse(String.t() | nil) :: {:ok, number()} | :error
  def parse(text) when is_binary(text) do
    case read(text) do
      {:ok, scaled} -> {:ok, number(scaled)}
      :error -> :error
    end
  end

  def parse(nil), do: :error

  @doc """
  `value` as text with exactly `precision` decimals, rounded half away from zero, and `decimal` as the separator.

      iex> DevactionUI.NumberInput.format(2.5, 2)
      "2.50"
      iex> DevactionUI.NumberInput.format("1.005", 2, ",")
      "1,01"
  """
  @spec format(amount(), non_neg_integer(), String.t()) :: String.t()
  def format(value, precision, decimal \\ ".") do
    {int, scale} = scaled!(value)
    int |> rescale(scale, precision) |> render(precision, decimal)
  end

  defp read(text) do
    case Regex.named_captures(@number, text) do
      %{"sign" => sign, "whole" => whole, "frac" => frac, "exp" => exp} ->
        {:ok,
         build(String.to_integer(sign <> whole <> frac), String.length(frac) - exponent(exp))}

      nil ->
        :error
    end
  end

  defp exponent(""), do: 0
  defp exponent(exp), do: String.to_integer(exp)

  defp build(int, scale) when scale < 0, do: {int * pow10(-scale), 0}
  defp build(int, scale), do: {int, scale}

  defp scaled!({_int, _scale} = scaled), do: scaled
  defp scaled!(number) when is_integer(number), do: {number, 0}

  defp scaled!(number) when is_float(number),
    do: number |> :erlang.float_to_binary([:short]) |> scaled!()

  defp scaled!(text) when is_binary(text) do
    case read(text) do
      {:ok, scaled} -> scaled
      :error -> raise ArgumentError, "not a number: #{inspect(text)}"
    end
  end

  defp scaled!(other), do: other |> to_string() |> scaled!()

  defp pow10(exponent), do: Integer.pow(10, exponent)

  defp add({a, scale_a}, {b, scale_b}) do
    scale = max(scale_a, scale_b)
    {a * pow10(scale - scale_a) + b * pow10(scale - scale_b), scale}
  end

  defp compare({a, scale_a}, {b, scale_b}) do
    scale = max(scale_a, scale_b)
    {x, y} = {a * pow10(scale - scale_a), b * pow10(scale - scale_b)}

    cond do
      x < y -> :lt
      x > y -> :gt
      true -> :eq
    end
  end

  defp held(value, min, max), do: value |> at_least(limit(min)) |> at_most(limit(max))

  defp limit(nil), do: nil
  defp limit(limit), do: scaled!(limit)

  defp at_least(value, nil), do: value

  defp at_least(value, min) do
    case compare(value, min) do
      :lt -> min
      _order -> value
    end
  end

  defp at_most(value, nil), do: value

  defp at_most(value, max) do
    case compare(value, max) do
      :gt -> max
      _order -> value
    end
  end

  defp trim({int, scale}) when scale > 0 and rem(int, 10) == 0,
    do: trim({div(int, 10), scale - 1})

  defp trim(scaled), do: scaled

  defp number(scaled) do
    case trim(scaled) do
      {int, 0} -> int
      {int, scale} -> int / pow10(scale)
    end
  end

  defp decimals(value), do: value |> scaled!() |> trim() |> elem(1)

  defp rescale(int, scale, precision) when scale <= precision, do: int * pow10(precision - scale)
  defp rescale(int, scale, precision), do: away(int, pow10(scale - precision))

  defp away(int, unit) when int < 0, do: -away(-int, unit)
  defp away(int, unit), do: div(2 * int + unit, 2 * unit)

  defp render(int, 0, _decimal), do: Integer.to_string(int)

  defp render(int, precision, decimal) do
    digits = int |> abs() |> Integer.to_string() |> String.pad_leading(precision + 1, "0")
    {whole, fraction} = String.split_at(digits, -precision)
    sign(int) <> whole <> decimal <> fraction
  end

  defp sign(int) when int < 0, do: "-"
  defp sign(_int), do: ""

  defp plain(nil), do: nil
  defp plain(value), do: format(value, decimals(value))

  defp negated(value) do
    {int, scale} = scaled!(value)
    {-int, scale}
  end

  defp floor?(_value, nil), do: false
  defp floor?(value, min), do: compare(scaled!(value), scaled!(min)) != :gt

  defp ceiling?(_value, nil), do: false
  defp ceiling?(value, max), do: compare(scaled!(value), scaled!(max)) != :lt

  attr :id, :string, required: true
  attr :name, :string, required: true

  attr :value, :any,
    required: true,
    doc: "a number or text that reads as one: `3`, `0.25`, `\"1,5\"`"

  attr :label, :string, required: true, doc: "what is counted, for assistive technology"
  attr :unit, :string, default: nil, doc: "shown beside the value and read with it: `h`, `seats`"
  attr :min, :any, default: nil, doc: "a number or text; the minus stops here"
  attr :max, :any, default: nil, doc: "a number or text; the plus stops here"
  attr :step, :any, default: 1, doc: "how far a press moves, whole or fractional: `1`, `0.25`"

  attr :precision, :integer,
    default: nil,
    doc: "decimals shown; defaults to the decimals of `step` and of the value"

  attr :decimal, :string,
    default: ".",
    doc: "the decimal separator shown and read: `\".\"` or `\",\"`"

  attr :event, :string,
    required: true,
    doc: "sent by the buttons and the keys, with `phx-value-step` (the signed amount, as text)"

  attr :decrease_label, :string, required: true
  attr :increase_label, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  slot :minus_icon, required: true
  slot :plus_icon, required: true
  slot :unit_mark, doc: "how the unit is drawn (`m<sup>2</sup>`); `unit` stays the text read out"
  slot :help, doc: "a line under the field, e.g. `Between 1 and 30`"

  attr :rest, :global

  def number_input(assigns) do
    assigns =
      assigns
      |> assign(:precision, precision(assigns))
      |> assign(:minus_step, plain(negated(assigns.step)))
      |> assign(:plus_step, plain(assigns.step))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.NumberInput"
      data-event={@event}
      data-step={@plus_step}
      data-min={plain(@min)}
      data-max={plain(@max)}
      data-precision={@precision}
      data-decimal={@decimal}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <div class={["number-input", @disabled && "opacity-60"]}>
        <button
          id={"#{@id}-minus"}
          type="button"
          aria-label={@decrease_label}
          aria-controls={"#{@id}-field"}
          disabled={@disabled or floor?(@value, @min)}
          phx-click={@event}
          phx-value-step={@minus_step}
          class="grid place-items-center text-lg outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:text-done-cell"
        >
          {render_slot(@minus_icon)}
        </button>
        <span class="flex flex-1 items-baseline justify-center gap-1.5">
          <input
            id={"#{@id}-field"}
            name={@name}
            type="text"
            inputmode={(@precision > 0 && "decimal") || "numeric"}
            role="spinbutton"
            aria-label={@label}
            aria-valuenow={format(@value, @precision)}
            aria-valuemin={plain(@min)}
            aria-valuemax={plain(@max)}
            aria-valuetext={@unit && "#{format(@value, @precision, @decimal)} #{@unit}"}
            aria-describedby={@help != [] && "#{@id}-help"}
            value={format(@value, @precision, @decimal)}
            disabled={@disabled}
            class="min-w-[2ch] border-0 bg-transparent p-0 text-center font-sans text-[17px] font-medium tabular-nums outline-none [field-sizing:content] focus:ring-0"
          />
          <span :if={@unit || @unit_mark != []} class="text-[13px] text-muted">
            {(@unit_mark != [] && render_slot(@unit_mark)) || @unit}
          </span>
        </span>
        <button
          id={"#{@id}-plus"}
          type="button"
          aria-label={@increase_label}
          aria-controls={"#{@id}-field"}
          disabled={@disabled or ceiling?(@value, @max)}
          phx-click={@event}
          phx-value-step={@plus_step}
          class="grid place-items-center text-lg outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:text-done-cell"
        >
          {render_slot(@plus_icon)}
        </button>
      </div>
      <p :if={@help != []} id={"#{@id}-help"} class="m-0 text-xs text-muted">{render_slot(@help)}</p>
    </div>
    """
  end

  defp precision(%{precision: nil, step: step, value: value}),
    do: max(decimals(step), decimals(value))

  defp precision(%{precision: precision}), do: precision
end
