defmodule DevactionUI.Dropdown do
  @moduledoc """
  A button that opens a menu of actions or a choice (sort by deadline, by value, by risk). The menu opens
  under the button; ↑ ↓ Home End move between items, Enter or Space chooses, Esc closes and returns to the
  button, a click outside closes it (`DevactionUI.Dropdown` hook).

  An item is a plain action (`role="menuitem"`) or one of a group of choices (`checked` is not nil, then
  `role="menuitemradio"` with a check mark). It sends `event` with `choice`, or goes to `navigate`. A
  `separator` puts a rule above the item, and `danger` colors it as destructive.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the menu, for assistive technology"
  attr :align, :atom, values: [:start, :end], default: :start
  attr :size, :atom, values: [:sm, :md], default: :md, doc: "the height of the button: 36 or 42px"
  attr :class, :any, default: nil
  slot :trigger, required: true, doc: "what the button shows"

  slot :item, required: true do
    attr :event, :string
    attr :value, :string
    attr :navigate, :string
    attr :checked, :boolean, doc: "set (true or false) for a choice; leave out for an action"
    attr :danger, :boolean
    attr :separator, :boolean
    attr :shortcut, :string
  end

  slot :check_icon, required: true, doc: "the check mark of the chosen item, drawn by the caller"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def dropdown(assigns) do
    ~H"""
    <div id={@id} phx-hook="DevactionUI.Dropdown" class={["relative inline-block", @class]} {@rest}>
      <button
        type="button"
        data-trigger
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-menu"}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        class={[
          "inline-flex items-center gap-2 whitespace-nowrap rounded-[11px] border border-line-strong bg-card text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10",
          (@size == :sm && "h-9 px-3 text-sm") || "h-[42px] px-3.5"
        ]}
      >
        {render_slot(@trigger)}
      </button>
      <div
        id={"#{@id}-menu"}
        data-menu
        role="menu"
        aria-label={@label}
        hidden
        phx-mounted={JS.ignore_attributes(["hidden"])}
        class={[
          "absolute z-40 mt-2 flex w-60 flex-col rounded-[14px] border border-line bg-card p-1.5 shadow-[0_16px_40px_rgba(24,24,27,0.12)]",
          (@align == :end && "right-0") || "left-0"
        ]}
      >
        <%= for item <- @item do %>
          <span
            :if={Map.get(item, :separator)}
            class="mx-1 my-1.5 h-px bg-line-soft"
            role="separator"
          />
          <.menu_item item={item} check_icon={@check_icon} target={@target} />
        <% end %>
      </div>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :check_icon, :list, required: true
  attr :target, :any, default: nil

  defp menu_item(assigns) do
    assigns = assign(assigns, :checked, Map.get(assigns.item, :checked))

    ~H"""
    <.link
      :if={Map.has_key?(@item, :navigate)}
      navigate={@item.navigate}
      role="menuitem"
      tabindex="-1"
      class={item_class(@item)}
    >
      {render_slot(@item)}<kbd
        :if={Map.get(@item, :shortcut)}
        class="font-mono text-[11px] text-muted"
      >{@item.shortcut}</kbd>
    </.link>
    <button
      :if={not Map.has_key?(@item, :navigate)}
      type="button"
      role={(is_nil(@checked) && "menuitem") || "menuitemradio"}
      aria-checked={not is_nil(@checked) && to_string(@checked)}
      tabindex="-1"
      phx-click={Map.get(@item, :event)}
      phx-target={@target}
      phx-value-choice={Map.get(@item, :value)}
      class={[item_class(@item), @checked && "bg-wrap"]}
    >
      {render_slot(@item)}
      <kbd :if={Map.get(@item, :shortcut)} class="font-mono text-[11px] text-muted">{@item.shortcut}</kbd>
      <span :if={@checked} aria-hidden="true">{render_slot(@check_icon)}</span>
    </button>
    """
  end

  defp item_class(item) do
    [
      "flex h-[38px] w-full items-center justify-between gap-3 rounded-[9px] border-0 bg-transparent px-2.5 text-left text-sm no-underline outline-none hover:bg-wrap focus-visible:bg-wrap",
      (Map.get(item, :danger) && "text-tag-risk-text") || "text-ink"
    ]
  end
end
