defmodule DevactionUI.Select do
  @moduledoc """
  A plain select: the browser's own `<select>` in the frame of the input group, for a short list that needs no
  search (a status, a role, a currency). For a long list, or one that is searched, use `DevactionUI.Combobox`.

  Options are `{label, value}` tuples, a keyword list, plain strings, `%{value: ..., label: ...}` maps (with an
  optional `disabled: true`), or groups `{"Group", [options]}` that become `<optgroup>`s. `prompt` is a first
  empty option (`Choose a status`), drawn in the muted text of a placeholder while it is the choice.

  `multiple` is the native list box: the name ends in `[]` and the value is a list. With
  `field={@form[:status]}` the id, the name, the value and the error state come from the form (see
  `DevactionUI.FormField`); what is given by hand wins. The error message is not drawn here: wrap the select in
  `DevactionUI.Field`, as any other input.

  The arrow and the leading icon are slots (the library knows no icon set); without `chevron_icon` the arrow is
  a `⌄`. Sizes follow the input group: `:sm` 36px, `:md` 44px, `:lg` 52px.
  """
  use Phoenix.Component

  alias DevactionUI.FormField

  attr :id, :string, default: nil, doc: "required unless a `field` gives it"
  attr :name, :string, default: nil

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc:
      "a form field (`@form[:status]`): gives the `id`, the `name`, the value and the error state"

  attr :options, :list,
    required: true,
    doc:
      "`{label, value}`, strings, `%{value, label, disabled}` maps or `{group, options}` groups"

  attr :value, :any, default: nil, doc: "the chosen value, or a list of them with `multiple`"
  attr :prompt, :string, default: nil, doc: "a first empty option, such as `Choose a status`"
  attr :multiple, :boolean, default: false, doc: "the native list box; the name ends in `[]`"
  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "36, 44 or 52 px high"
  attr :invalid, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form autofocus autocomplete)

  slot :icon, doc: "drawn before the text, muted"
  slot :chevron_icon, doc: "the arrow at the end; a `⌄` when there is none"

  @doc "A native select in the frame of the input group."
  def select(assigns) do
    assigns =
      assigns
      |> FormField.put(value: :raw, multiple: assigns.multiple)
      |> FormField.require!([:id], "select/1")

    assigns =
      assign(assigns,
        invalid: assigns.invalid or assigns.field_errors != [],
        options: normalize(assigns.options)
      )

    ~H"""
    <span
      id={"#{@id}-group"}
      class={["input-group select", size_class(@size), @multiple && "select-multiple", @class]}
    >
      <span :if={@icon != []} class="input-icon [&>*]:size-full">{render_slot(@icon)}</span>
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        aria-invalid={@invalid && "true"}
        {@rest}
      >
        <option :if={@prompt && !@multiple} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, selected(@value))}
      </select>
      <span :if={!@multiple} class="select-chevron" aria-hidden="true">
        {render_slot(@chevron_icon)}<span :if={@chevron_icon == []}>⌄</span>
      </span>
    </span>
    """
  end

  # maps of the library (`%{value, label, disabled}`) become the keyword options of Phoenix.HTML
  defp normalize(options), do: Enum.map(options, &option/1)

  defp option({group, options}) when is_list(options), do: {group, normalize(options)}

  defp option(%{value: value, label: label} = option),
    do: [key: label, value: value, disabled: Map.get(option, :disabled, false)]

  defp option(other), do: other

  defp selected(nil), do: nil
  defp selected(values) when is_list(values), do: Enum.map(values, &FormField.text/1)
  defp selected(value), do: FormField.text(value)

  defp size_class(:sm), do: "input-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "input-lg"
end
