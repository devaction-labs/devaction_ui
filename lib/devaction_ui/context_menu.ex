defmodule DevactionUI.ContextMenu do
  @moduledoc """
  A menu of actions that opens on a right click, or on Shift + F10 (or the menu key) while the focus is in the area it
  belongs to, at the pointer and not under a button (`DevactionUI.ContextMenu` hook). The area is the `area` slot, such as the row of
  a list; the menu is the same as the one `DevactionUI.Dropdown` draws (icons, a shortcut at the right of an item,
  separators, a `danger` item) and it takes the same `item` slots, so the items are written once: with a `more` slot
  (the "···" icon) and a `more_label` the target also gets a button at its right that opens those same items as a
  dropdown, for whoever has no right button.

  The menu is placed at the pointer, or at the focused element for the keyboard, and kept inside the window: it opens
  to the left or upwards of the point when it would not fit. ↑ ↓ Home End move round the items, the first letters
  of a name jump to an item, Enter or Space chooses, Esc closes it and gives the focus back to where it was, and
  so do Tab, a click outside, a scroll and a resize. The target carries `data-open` while its menu is open. The menu
  is `position: fixed`, so keep the component out of an ancestor with a `transform`, which would turn that point
  into its own corner.

  An item is an action: it sends `event` with `value` as `choice` and `values` as `phx-value-*` to `target`, or goes
  to `navigate`, `patch` or `href`; `disabled` leaves it out of the keys. A `separator` puts a rule above the item and a
  `heading` a small caption.
  """
  use Phoenix.Component

  alias DevactionUI.Dropdown
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the menu, for assistive technology"

  attr :more_label, :string,
    default: nil,
    doc:
      "the accessible name of the \"···\" button; with the `more` slot, it shows the same items as a dropdown"

  attr :focusable, :boolean,
    default: true,
    doc:
      "puts the target in the Tab order, so the keyboard can reach its menu (false when what it holds is already focusable)"

  attr :class, :any, default: nil, doc: "classes of the wrapper"
  attr :target_class, :any, default: nil, doc: "classes of the area that opens the menu"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  slot :area, required: true, doc: "the area that opens the menu: the row, the card"
  slot :more, doc: "the icon of the \"···\" button; leave it out for a menu with no button"

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

  @spec menu(map()) :: Phoenix.LiveView.Rendered.t()
  def menu(assigns) do
    ~H"""
    <div id={@id} phx-hook="DevactionUI.ContextMenu" class={["relative", @class]} {@rest}>
      <div
        data-target
        tabindex={@focusable && "0"}
        aria-haspopup="menu"
        phx-mounted={JS.ignore_attributes(["data-open"])}
        class={[
          "relative outline-none focus-visible:ring-2 focus-visible:ring-ink focus-visible:ring-inset data-[open]:bg-wrap data-[open]:ring-2 data-[open]:ring-ink data-[open]:ring-inset",
          @more != [] && "pr-12",
          @target_class
        ]}
      >
        {render_slot(@area)}
        <span
          :if={@more != [] and @more_label != nil}
          class="absolute top-1/2 right-2 -translate-y-1/2"
        >
          <Dropdown.dropdown
            id={"#{@id}-more"}
            label={@label}
            variant={:icon}
            size={:sm}
            align={:end}
            trigger_label={@more_label}
            target={@target}
            trigger_class="bg-transparent!"
          >
            <:trigger>{render_slot(@more)}</:trigger>
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
        </span>
      </div>
      <div
        id={"#{@id}-menu"}
        data-context-menu
        role="menu"
        aria-label={@label}
        tabindex="-1"
        hidden
        phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        class="fixed top-0 left-0 z-50 flex w-62.5 max-w-[calc(100vw-1rem)] flex-col rounded-xl border border-line bg-card p-1.5 shadow-menu outline-none"
      >
        <%= for item <- @item do %>
          <span
            :if={Map.get(item, :separator)}
            class="mx-1 my-1.5 h-px bg-line-soft"
            role="separator"
          />
          <span
            :if={Map.get(item, :heading)}
            role="presentation"
            class="px-2.5 pt-1.5 pb-1 font-mono text-[10px] uppercase tracking-[0.08em] text-muted"
          >
            {item.heading}
          </span>
          <Dropdown.menu_item item={item} target={@target} compact />
        <% end %>
      </div>
    </div>
    """
  end
end
