defmodule DevactionUI.MoneyInput do
  @moduledoc """
  A field for Brazilian reais (BRL, on purpose: the mask has the `R$` add-on, the dot for thousands and the comma
  for the cents): the person types digits and the field shows `1.234,56` after the `R$`, the last two digits
  being the cents (`DevactionUI.MoneyMask` in `assets/js/devaction_ui`, which also formats the value the server
  renders it with and the one it patches in). What is sent is the text as shown; the server reads it with
  `parse/1`.

  It is an `InputGroup` with the `R$` add-on, so the height, the focus ring and the error look are the ones of the
  other text fields. The error messages sit under it and the field points at them with `aria-describedby`, joined
  to one the caller gives.
  """
  use Phoenix.Component

  import DevactionUI.InputGroup

  @doc """
  The amount of a masked text in cents, or `:error` when it holds no digits. Cents are an integer, so
  nothing here depends on a decimal library. The sign is not read: an amount is never negative here.

      iex> DevactionUI.MoneyInput.parse("R$ 1.234,56")
      {:ok, 123_456}
  """
  @spec parse(String.t() | nil) :: {:ok, non_neg_integer()} | :error
  def parse(text) when is_binary(text), do: text |> String.replace(~r/\D/, "") |> cents()
  def parse(nil), do: :error

  defp cents(""), do: :error
  defp cents(digits), do: {:ok, String.to_integer(digits)}

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :label, :string, required: true
  attr :placeholder, :string, default: "0,00"
  attr :errors, :list, default: [], doc: "messages to show under the field"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(disabled readonly required autocomplete form),
    doc: "goes to the `<input>`"

  def money_input(assigns) do
    assigns =
      assigns
      |> assign(:describedby, describedby(assigns.rest[:"aria-describedby"], assigns))
      |> assign(:rest, Map.delete(assigns.rest, :"aria-describedby"))

    ~H"""
    <div class={["flex flex-col gap-1.5", @class]}>
      <label for={@id} class="text-[13px] font-medium text-ink">{@label}</label>
      <.input_group
        id={@id}
        name={@name}
        value={@value}
        inputmode="decimal"
        placeholder={@placeholder}
        invalid={@errors != []}
        aria-describedby={@describedby}
        phx-hook="DevactionUI.MoneyMask"
        class="[&>input]:text-right [&>input]:tabular-nums"
        {@rest}
      >
        <:prefix mono>R$</:prefix>
      </.input_group>
      <p :if={@errors != []} id={"#{@id}-error"} class="m-0 text-[13px] text-missing">
        {Enum.join(@errors, " ")}
      </p>
    </div>
    """
  end

  defp describedby(given, %{errors: []}), do: given
  defp describedby(nil, assigns), do: "#{assigns.id}-error"
  defp describedby(given, assigns), do: "#{given} #{assigns.id}-error"
end
