defmodule DevactionUI.Pillbox do
  @moduledoc """
  A field of removable pills, for labels, e-mails, stacks: type and press Enter (or a comma) to add one,
  Backspace on an empty field removes the last, the × on a pill removes that one. Each pill is a hidden
  input named `name[]`, so the form submits the list as it stands; the hook fires `input` on the box so
  `phx-change` hears every change. The browser owns the pills after mount (`phx-update="ignore"`): give
  it a new `id` to reset it from the server.

  Text left in the field when it loses focus is added as a pill (Enter and the comma add it too). With every
  pill removed the form sends nothing for `name[]`: read the field with `Map.get(params, "name", [])` and take
  the absence as an empty list. `remove_label`, `added_label` and `removed_label` take `%{label}`, which the
  server and the hook fill with the text of the pill; the last two are announced in a polite live region.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "the field name; the values are sent as `name[]`"

  attr :values, :list,
    default: [],
    doc:
      "the pills of the first render only: the browser owns them after mount, so a new list needs a new `id`"

  attr :label, :string, required: true, doc: "what the field is, for assistive technology"
  attr :placeholder, :string, default: nil

  attr :remove_label, :string,
    required: true,
    doc: "names the × of each pill; `%{label}` is the pill's text, as in `\"Remove %{label}\"`"

  attr :added_label, :string,
    default: nil,
    doc: "announced when a pill is added, as in `\"%{label} added\"`"

  attr :removed_label, :string,
    default: nil,
    doc: "announced when a pill is removed, as in `\"%{label} removed\"`"

  attr :disabled, :boolean, default: false

  attr :input_rest, :map,
    default: %{},
    doc:
      "attributes of the text field itself, such as `aria-describedby`, `aria-invalid` or `required`"

  attr :class, :any, default: nil

  attr :rest, :global
  slot :remove_icon, doc: "replaces the typographic × that removes a pill"

  def pillbox(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Pillbox"
      phx-update="ignore"
      data-name={@name}
      data-remove-label={@remove_label}
      data-added-label={@added_label}
      data-removed-label={@removed_label}
      class={[
        "flex min-h-11 flex-wrap items-center gap-1.5 rounded-xl border border-line-strong bg-card px-2 py-1.5 focus-within:border-ink focus-within:ring-4 focus-within:ring-ink/10",
        @class
      ]}
      {@rest}
    >
      <.pill
        :for={value <- @values}
        name={@name}
        value={value}
        remove_label={fill_label(@remove_label, value)}
        disabled={@disabled}
      />
      <input
        type="text"
        aria-label={@label}
        placeholder={@placeholder}
        autocomplete="off"
        disabled={@disabled}
        class="min-w-[90px] flex-1 border-0 bg-transparent p-1 text-sm text-ink outline-none placeholder:text-muted focus:ring-0 disabled:cursor-not-allowed"
        {@input_rest}
      />
      <span class="sr-only" role="status" aria-live="polite" data-live></span>
      <template data-pill>
        <.pill name={@name} value="" remove_label={@remove_label} disabled={@disabled}>
          <:remove_icon :if={@remove_icon != []}>{render_slot(@remove_icon)}</:remove_icon>
        </.pill>
      </template>
    </div>
    """
  end

  defp fill_label(pattern, label), do: String.replace(pattern, "%{label}", label)

  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :remove_label, :string, required: true
  attr :disabled, :boolean, default: false
  slot :remove_icon

  defp pill(assigns) do
    ~H"""
    <span
      data-pill-item
      class="inline-flex h-[30px] items-center gap-1 rounded-lg border border-line bg-wrap pr-1 pl-2.5 text-[13px] text-ink"
    >
      <span data-label>{@value}</span>
      <input type="hidden" name={@name <> "[]"} value={@value} />
      <button
        type="button"
        data-remove
        aria-label={@remove_label}
        disabled={@disabled}
        class="flex size-[22px] items-center justify-center rounded-md text-muted outline-none hover:bg-line focus-visible:ring-2 focus-visible:ring-ink/20 disabled:cursor-not-allowed"
      >
        <span aria-hidden="true">{render_slot(@remove_icon) || "×"}</span>
      </button>
    </span>
    """
  end
end
