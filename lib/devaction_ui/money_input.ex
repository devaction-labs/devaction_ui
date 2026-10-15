defmodule DevactionUI.MoneyInput do
  @moduledoc """
  A field for Brazilian money: the person types digits and the field shows `R$ 1.234,56`, the last two
  digits being the cents (`DevactionUI.MoneyMask` in `assets/js/devaction_ui`). What is sent is the text as
  shown; the server reads it with `parse/1`.
  """
  use Phoenix.Component

  @doc """
  The amount of a masked text in cents, or `:error` when it holds no digits. Cents are an integer, so
  nothing here depends on a decimal library.

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
  attr :errors, :list, default: [], doc: "messages to show under the field"
  attr :class, :any, default: nil
  attr :rest, :global

  def money_input(assigns) do
    ~H"""
    <div class={["flex flex-col gap-1.5", @class]}>
      <label for={@id} class="text-[13px] font-medium text-ink">{@label}</label>
      <input
        id={@id}
        type="text"
        inputmode="numeric"
        name={@name}
        value={@value}
        phx-hook="DevactionUI.MoneyMask"
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && "#{@id}-error"}
        class={[
          "h-[46px] rounded-xl border bg-card px-3.5 text-[15px] text-ink outline-none focus:border-ink focus:ring-4 focus:ring-ink/10",
          (@errors == [] && "border-line-strong") || "border-missing"
        ]}
        {@rest}
      />
      <p :if={@errors != []} id={"#{@id}-error"} class="m-0 text-[13px] text-missing">
        {Enum.join(@errors, " ")}
      </p>
    </div>
    """
  end
end
