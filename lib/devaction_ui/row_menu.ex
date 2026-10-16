defmodule DevactionUI.RowMenu do
  @moduledoc """
  The "..." menu of a row: a small icon button that opens a menu of actions fixed to the window, so the `overflow`
  of a table or of a scroll area never cuts it. It is a `DevactionUI.Dropdown` with `fixed` on and the quiet 30px
  button of a table row, and it takes the same `item` slots (icons, a shortcut, separators, a `danger` item, links
  with `navigate`, `patch` or `href`), so the keys are the same: ↑ ↓ Home End, the first letters of a name, Esc
  gives the focus back to the button.

  The menu opens under the button with its end on the end of the button, above it when there is no room below,
  and stays inside the window. It closes when anything scrolls or the window is resized, because it would no
  longer sit under its button. The icon of the button comes in the `trigger` slot and its accessible name in
  `trigger_label` (there is no visible text).
  """
  use Phoenix.Component

  alias DevactionUI.Dropdown

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the menu, for assistive technology"
  attr :trigger_label, :string, required: true, doc: "the accessible name of the \"...\" button"
  attr :align, :atom, values: [:start, :end], default: :end
  attr :class, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  slot :trigger, required: true, doc: "the icon of the button"

  slot :item, required: true do
    attr :event, :string
    attr :value, :string, doc: "sent as `choice`"
    attr :values, :map, doc: "one `phx-value-*` each, besides `choice`"
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :danger, :boolean
    attr :disabled, :boolean
    attr :separator, :boolean, doc: "a rule above the item"
    attr :heading, :string, doc: "a caption above the item, for the group it starts"
    attr :shortcut, :string
  end

  attr :rest, :global

  @spec row_menu(map()) :: Phoenix.LiveView.Rendered.t()
  def row_menu(assigns) do
    ~H"""
    <Dropdown.dropdown
      id={@id}
      label={@label}
      variant={:icon}
      size={:sm}
      align={@align}
      fixed
      compact
      trigger_label={@trigger_label}
      target={@target}
      class={["align-middle", @class]}
      trigger_class="size-7.5! rounded-lg! bg-transparent! text-ink-2 hover:bg-wrap! hover:text-ink"
      {@rest}
    >
      <:trigger>{render_slot(@trigger)}</:trigger>
      <:item
        :for={item <- @item}
        event={Map.get(item, :event)}
        value={Map.get(item, :value)}
        values={Map.get(item, :values)}
        navigate={Map.get(item, :navigate)}
        patch={Map.get(item, :patch)}
        href={Map.get(item, :href)}
        danger={Map.get(item, :danger)}
        disabled={Map.get(item, :disabled)}
        separator={Map.get(item, :separator)}
        heading={Map.get(item, :heading)}
        shortcut={Map.get(item, :shortcut)}
      >
        {render_slot(item)}
      </:item>
    </Dropdown.dropdown>
    """
  end
end
