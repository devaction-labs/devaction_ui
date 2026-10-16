defmodule DevactionUI.Choice do
  @moduledoc """
  Boxes to tick and options to pick, as the canvas draws them: the checkbox (with the partial state of "select
  all"), the radio with its description and the choice card. They are real `<input>`s, so the browser, the form
  and the keyboard do the work; the look comes from the `checkbox`, `radio` and `choice-card` classes.

  `checkbox_group/1` and `radio_group/1` are the `<fieldset>` with its `<legend>` that name a set of boxes or
  options, with a help text, an error and the required mark of the group. The radio group is a `radiogroup`
  whose arrow keys are the browser's own for radios sharing a `name`. `size={:sm}` is the 18px box on a 40px
  row for dense lists, and `variant={:task}` on a checkbox is the round 22px tick of a task list, whose text is
  struck through once it is done.
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
  attr :size, :atom, values: [:md, :sm], default: :md

  attr :variant, :atom,
    values: [:default, :task],
    default: :default,
    doc: "`:task` is the round tick of a task list; the text is struck through once it is checked"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form autofocus)

  def checkbox(assigns) do
    ~H"""
    <label class={["choice-label", size_class(@size), variant_class(@variant), @class]}>
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
  attr :size, :atom, values: [:md, :sm], default: :md
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form autofocus)

  def radio(assigns) do
    ~H"""
    <label class={["choice-label", size_class(@size), @class]}>
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

  attr :invalid, :boolean, default: false, doc: "the card is drawn with the border of an error"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form autofocus)
  slot :icon, doc: "a mark at the start of the card"

  @doc "A whole card that is the option: it gains the border and the wash of the choice when ticked."
  def choice_card(assigns) do
    ~H"""
    <label class={["choice-card", @class]} data-invalid={@invalid && "true"}>
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
          aria-invalid={@invalid && "true"}
          class={[input_class(@type), order_class(@layout)]}
          {@rest}
        />
      </span>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :legend, :string, required: true, doc: "what the boxes choose, as the group's name"
  attr :help, :string, default: nil, doc: "a hint under the boxes, tied to the group"
  attr :error, :string, default: nil, doc: "what is wrong with the group, as an alert"

  attr :required, :boolean,
    default: false,
    doc: "marks the legend with an asterisk; put `required` on the boxes that must be ticked"

  attr :orientation, :atom, values: [:vertical, :horizontal], default: :vertical
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form)
  slot :inner_block, required: true, doc: "the `checkbox/1`s of the group"

  @doc "A `<fieldset>` with a `<legend>` around a set of checkboxes, with the help and the error of the group."
  def checkbox_group(assigns) do
    ~H"""
    <.group
      id={@id}
      legend={@legend}
      help={@help}
      error={@error}
      required={@required}
      orientation={@orientation}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.group>
    """
  end

  attr :id, :string, required: true
  attr :legend, :string, required: true, doc: "what the options choose, as the group's name"
  attr :help, :string, default: nil, doc: "a hint under the options, tied to the group"
  attr :error, :string, default: nil, doc: "what is wrong with the group, as an alert"

  attr :required, :boolean,
    default: false,
    doc: "marks the group as required, for assistive technology and with an asterisk"

  attr :orientation, :atom, values: [:vertical, :horizontal], default: :vertical
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form)
  slot :inner_block, required: true, doc: "the `radio/1`s or `choice_card/1`s of the group"

  @doc "A `radiogroup` `<fieldset>` with a `<legend>` around radios that share a `name`; the arrow keys are the browser's."
  def radio_group(assigns) do
    ~H"""
    <.group
      id={@id}
      role="radiogroup"
      aria-required={@required && "true"}
      legend={@legend}
      help={@help}
      error={@error}
      required={@required}
      orientation={@orientation}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.group>
    """
  end

  attr :id, :string, required: true
  attr :legend, :string, required: true
  attr :help, :string, default: nil
  attr :error, :string, default: nil
  attr :required, :boolean, default: false
  attr :orientation, :atom, values: [:vertical, :horizontal], required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form role aria-required)
  slot :inner_block, required: true

  defp group(assigns) do
    ~H"""
    <fieldset
      id={@id}
      aria-describedby={describedby(@id, @help, @error)}
      aria-invalid={@error && "true"}
      class={["choice-group", @class]}
      {@rest}
    >
      <legend class="choice-legend">
        {@legend}<span :if={@required} aria-hidden="true" class="ml-0.5 text-missing">*</span>
      </legend>
      <div class={["flex", group_class(@orientation)]}>{render_slot(@inner_block)}</div>
      <p :if={@help} id={@id <> "-help"} class="choice-desc m-0">{@help}</p>
      <p :if={@error} id={@id <> "-error"} role="alert" class="m-0 text-[13px] text-risk-fg">
        {@error}
      </p>
    </fieldset>
    """
  end

  defp group_class(:vertical), do: "flex-col"
  defp group_class(:horizontal), do: "flex-wrap gap-x-4"

  defp describedby(id, help, error),
    do: [help && id <> "-help", error && id <> "-error"] |> Enum.filter(& &1) |> joined()

  defp joined([]), do: nil
  defp joined(ids), do: Enum.join(ids, " ")

  defp size_class(:md), do: nil
  defp size_class(:sm), do: "choice-sm"

  defp variant_class(:default), do: nil
  defp variant_class(:task), do: "choice-task"

  defp layout_class(:row), do: "items-start"
  defp layout_class(:stack), do: "flex-col items-start"

  defp order_class(:row), do: nil
  defp order_class(:stack), do: "order-first"

  defp input_class("radio"), do: "radio"
  defp input_class(_type), do: "checkbox"
end
