defmodule DevactionUI.Choice do
  @moduledoc """
  Boxes to tick and options to pick, as the canvas draws them: the checkbox (with the partial state of "select
  all"), the radio with its description and the choice card. They are real `<input>`s, so the browser, the form
  and the keyboard do the work; the look comes from the `checkbox`, `radio` and `choice-card` classes.
  """
  use Phoenix.Component

  @doc "The state of a \"select all\" box: `:none`, `:some` (partial) or `:all`, from how many of `total` are ticked."
  @spec select_all_state(non_neg_integer(), non_neg_integer()) :: :none | :some | :all
  def select_all_state(_total, 0), do: :none
  def select_all_state(total, total), do: :all
  def select_all_state(_total, _checked), do: :some

  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :string, default: "true"
  attr :checked, :boolean, default: false

  attr :partial, :boolean,
    default: false,
    doc:
      "the dash of a \"select all\" with only some ticked; the `DevactionUI.Indeterminate` hook sets the element's `indeterminate` so assistive technology hears it too"

  attr :label, :string, default: nil
  attr :description, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form)

  def checkbox(assigns) do
    ~H"""
    <label class={["choice-label", @class]}>
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked and not @partial}
        data-partial={@partial && "true"}
        phx-hook="DevactionUI.Indeterminate"
        class="checkbox"
        {@rest}
      />
      <span :if={@label} class="flex flex-col">
        <span class="font-medium">{@label}</span>
        <span :if={@description} class="choice-desc">{@description}</span>
      </span>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :checked, :boolean, default: false
  attr :label, :string, required: true
  attr :description, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form)

  def radio(assigns) do
    ~H"""
    <label class={["choice-label", @class]}>
      <input
        type="radio"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        class="radio"
        {@rest}
      />
      <span class="flex flex-col">
        <span class="font-medium">{@label}</span>
        <span :if={@description} class="choice-desc">{@description}</span>
      </span>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :type, :string, values: ["radio", "checkbox"], default: "radio"
  attr :checked, :boolean, default: false
  attr :label, :string, required: true
  attr :description, :string, default: nil

  attr :layout, :atom,
    values: [:row, :stack],
    default: :row,
    doc:
      "`:row` puts the mark, the text and the input in a line; `:stack` puts the mark above the text"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form)
  slot :icon, doc: "a mark at the start of the card"

  @doc "A whole card that is the option: it gains the border and the wash of the choice when ticked."
  def choice_card(assigns) do
    ~H"""
    <label class={["choice-card", @class]}>
      <span class={["flex gap-3", layout_class(@layout)]}>
        <span :if={@icon != []} class="mt-0.5 size-5 shrink-0 text-ink-2">
          {render_slot(@icon)}
        </span>
        <span class="flex flex-1 flex-col gap-0.5">
          <span class="font-medium text-ink">{@label}</span>
          <span :if={@description} class="choice-desc">{@description}</span>
        </span>
        <input
          type={@type}
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          class={[input_class(@type), order_class(@layout)]}
          {@rest}
        />
      </span>
    </label>
    """
  end

  defp layout_class(:row), do: "items-start"
  defp layout_class(:stack), do: "flex-col items-start"

  defp order_class(:row), do: nil
  defp order_class(:stack), do: "order-first"

  defp input_class("radio"), do: "radio"
  defp input_class(_type), do: "checkbox"
end
