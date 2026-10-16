defmodule DevactionUI.MoneyInput do
  @moduledoc """
  A field for an amount of money: the person types digits and the field shows `1.234,56`, the last digits being
  the minor units (cents). It is the Brazilian real by default (`prefix` `R$`, `decimal` `,`, `group` `.`,
  `precision` 2) and any other currency through those attrs:

      <MoneyInput.money_input id="usd" name="usd" label="Price" prefix="$" decimal="." group="," />
      <MoneyInput.money_input id="eur" name="eur" label="Preis" prefix={nil} suffix="€" group=" " />
      <MoneyInput.money_input id="jpy" name="jpy" label="Price" prefix="¥" precision={0} group="," />

  `DevactionUI.MoneyMask` (in `assets/js/devaction_ui`) formats what is typed, the value the server renders and the
  one it patches in, and keeps the caret among the same digits; the server renders the same text itself
  (`mask/2`), so the field is right before the hook runs. What is sent is the text as shown, and the server reads
  it with `parse/2`: the amount in minor units, an integer, so nothing depends on a decimal library. With `signed`
  a `-` anywhere in the text makes the amount negative.

  It is an `InputGroup` with the `prefix` add-on, so the height, the focus ring and the error, disabled and
  readonly looks are the ones of the other text fields. The label is the `label` text, or the `label_content`
  slot when it needs markup; the `help` slot and the error messages sit under the field and the field points at
  them with `aria-describedby`, joined to one the caller gives.
  """
  use Phoenix.Component

  import DevactionUI.InputGroup

  @non_digit ~r/\D/

  @doc """
  The amount of a masked text in minor units (cents), or `:error` when it holds no digits. The sign is read only
  with `signed: true`.

      iex> DevactionUI.MoneyInput.parse("R$ 1.234,56")
      {:ok, 123_456}
      iex> DevactionUI.MoneyInput.parse("-1,50", signed: true)
      {:ok, -150}
      iex> DevactionUI.MoneyInput.parse("-1,50")
      {:ok, 150}
  """
  @spec parse(String.t() | nil, keyword()) :: {:ok, integer()} | :error
  def parse(text, opts \\ [])

  def parse(text, opts) when is_binary(text),
    do: text |> digits() |> minor(negative?(text, opts))

  def parse(nil, _opts), do: :error

  @doc """
  An amount in minor units as the text the field shows. The options are `:decimal`, `:group` and `:precision`.

      iex> DevactionUI.MoneyInput.format(123_456)
      "1.234,56"
      iex> DevactionUI.MoneyInput.format(-5, decimal: ".", group: ",")
      "-0.05"
      iex> DevactionUI.MoneyInput.format(1234, precision: 0, group: ",")
      "1,234"
  """
  @spec format(integer(), keyword()) :: String.t()
  def format(amount, opts \\ []) when is_integer(amount) do
    precision = Keyword.get(opts, :precision, 2)

    digits = amount |> abs() |> Integer.to_string() |> String.pad_leading(precision + 1, "0")
    {whole, fraction} = String.split_at(digits, String.length(digits) - precision)

    sign(amount) <>
      group(whole, Keyword.get(opts, :group, ".")) <>
      decimal(fraction, Keyword.get(opts, :decimal, ","))
  end

  @doc """
  What the field shows for a typed text, a masked one, or an amount in minor units: the digits as money, and
  nothing for no digits. A `-` is kept only with `signed: true`, and alone it is a sign waiting for its digits.

      iex> DevactionUI.MoneyInput.mask("123456")
      "1.234,56"
      iex> DevactionUI.MoneyInput.mask(123_456)
      "1.234,56"
      iex> DevactionUI.MoneyInput.mask("-")
      ""
      iex> DevactionUI.MoneyInput.mask("-", signed: true)
      "-"
  """
  @spec mask(String.t() | integer() | nil, keyword()) :: String.t()
  def mask(value, opts \\ [])
  def mask(nil, _opts), do: ""
  def mask(value, opts) when is_integer(value), do: value |> Integer.to_string() |> mask(opts)

  def mask(text, opts) do
    sign = (negative?(text, opts) && "-") || ""

    case digits(text) do
      "" -> sign
      digits -> sign <> format(String.to_integer(digits), opts)
    end
  end

  defp digits(text), do: String.replace(text, @non_digit, "")

  defp negative?(text, opts),
    do: Keyword.get(opts, :signed, false) and String.contains?(text, "-")

  defp minor("", _negative?), do: :error
  defp minor(digits, true), do: {:ok, -String.to_integer(digits)}
  defp minor(digits, false), do: {:ok, String.to_integer(digits)}

  defp sign(amount) when amount < 0, do: "-"
  defp sign(_amount), do: ""

  defp group(whole, group),
    do: Regex.replace(~r/\B(?=(\d{3})+(?!\d))/, whole, fn _ -> group end)

  defp decimal("", _decimal), do: ""
  defp decimal(fraction, decimal), do: decimal <> fraction

  attr :id, :string, required: true
  attr :name, :string, required: true

  attr :value, :any,
    default: "",
    doc: "the amount in minor units (an integer) or text, masked or not; formatted on render"

  attr :label, :string, default: nil, doc: "the visible label; or give `label_content`"
  attr :prefix, :any, default: "R$", doc: "the add-on before the amount; `nil` for none"
  attr :suffix, :any, default: nil, doc: "an add-on after the amount, for `1,23 €`"
  attr :decimal, :string, default: ",", doc: "between the whole part and the minor units"
  attr :group, :string, default: ".", doc: "between the groups of three digits; `\"\"` for none"
  attr :precision, :integer, default: 2, doc: "digits of minor units: 2 for cents, 0 for yen"
  attr :signed, :boolean, default: false, doc: "a `-` makes the amount negative"
  attr :placeholder, :string, default: nil, doc: "defaults to a zero amount, like `0,00`"
  attr :errors, :list, default: [], doc: "messages to show under the field"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(disabled readonly required autocomplete form),
    doc: "goes to the `<input>`"

  slot :label_content, doc: "a label with markup, in place of `label`"
  slot :help, doc: "a line under the field, before the errors"

  def money_input(%{label: nil, label_content: []}),
    do: raise(ArgumentError, "money_input/1 needs a label or a label_content slot")

  def money_input(assigns) do
    opts = [
      decimal: assigns.decimal,
      group: assigns.group,
      precision: assigns.precision,
      signed: assigns.signed
    ]

    assigns =
      assigns
      |> assign(:describedby, describedby(assigns))
      |> assign(:text, mask(assigns.value, opts))
      |> assign(:zero, format(0, opts))
      |> assign(:rest, Map.delete(assigns.rest, :"aria-describedby"))

    ~H"""
    <div class={["flex flex-col gap-1.5", @class]}>
      <label for={@id} class="text-[13px] font-medium text-ink">
        {(@label_content != [] && render_slot(@label_content)) || @label}
      </label>
      <.input_group
        id={@id}
        name={@name}
        value={@text}
        inputmode="decimal"
        placeholder={@placeholder || @zero}
        invalid={@errors != []}
        aria-describedby={@describedby}
        phx-hook="DevactionUI.MoneyMask"
        data-decimal={@decimal}
        data-group={@group}
        data-precision={@precision}
        data-signed={to_string(@signed)}
        class="[&>input]:text-right [&>input]:tabular-nums"
        {@rest}
      >
        <:prefix :if={@prefix} mono>{@prefix}</:prefix>
        <:suffix :if={@suffix} mono>{@suffix}</:suffix>
      </.input_group>
      <p :if={@help != []} id={"#{@id}-help"} class="m-0 text-xs text-muted">{render_slot(@help)}</p>
      <p :if={@errors != []} id={"#{@id}-error"} class="m-0 text-[13px] text-missing">
        {Enum.join(@errors, " ")}
      </p>
    </div>
    """
  end

  defp describedby(assigns) do
    [
      assigns.rest[:"aria-describedby"],
      assigns.help != [] && "#{assigns.id}-help",
      assigns.errors != [] && "#{assigns.id}-error"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
    |> presence()
  end

  defp presence(""), do: nil
  defp presence(text), do: text
end
