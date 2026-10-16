defmodule DevactionUI.NotificationCenter do
  @moduledoc """
  The panel that lists what happened since the person last looked.

  It has a header with a "mark all as read" action, tabs with the count of what is unread in each, the notifications grouped by day and a footer with the preferences and the full list.

  The server owns everything: the tab, the groups and what is read. The panel sends `tab_event` (with
  `phx-value-id` of the tab), `open_event` (with `phx-value-id` of the notification), `read_all_event`,
  `preferences_event` and `all_event`, each a string or a `%JS{}`; inside a LiveComponent give the `target`. The
  library carries no language and no icons: every word is an attr, and the `icon` slot receives the item and
  draws what goes in its tile, coloured by the item's `tone` (`:warn`, `:info`, `:risk`, `:ok`, `:neutral`...).

  A group is `%{id: ..., label: ..., items: [...]}` and an item is `%{id: ..., title: ..., meta: ...,
  tone: ..., unread: boolean}` (plus whatever the `icon` slot needs). An unread item has the warm tint, a dot and a
  heavier title; the dot says `unread_label` to assistive technology. Each tab is `%{id: ..., label: ...,
  count: integer | nil}`; a count that is `nil` or `0` is not shown.

  Keyboard: the `DevactionUI.NotificationCenter` hook moves the focus with ↑ ↓ Home End between the notifications
  and with ← → Home End between the tabs; Enter opens the focused notification and selects the focused tab, as
  for any button.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "the heading of the panel"

  attr :read_all_label, :string,
    required: true,
    doc: "the text of the \"mark all as read\" action"

  attr :read_all_event, :any,
    default: nil,
    doc: "string or `%JS{}`; the action is disabled when nothing is unread"

  attr :tabs_label, :string, required: true, doc: "names the tab list for assistive technology"
  attr :tabs, :list, required: true, doc: "`[%{id: ..., label: ..., count: integer | nil}]`"
  attr :tab, :string, required: true, doc: "the id of the selected tab"
  attr :tab_event, :any, default: nil, doc: "string or `%JS{}`, with `phx-value-id` of the tab"

  attr :groups, :list,
    required: true,
    doc:
      "`[%{id: ..., label: ..., items: [%{id: ..., title: ..., meta: ..., tone: ..., unread: ...}]}]`"

  attr :unread_label, :string,
    required: true,
    doc: "what the unread dot says to assistive technology"

  attr :empty_label, :string, required: true, doc: "shown when there is no group"
  attr :open_event, :any, default: nil, doc: "string or `%JS{}`, with `phx-value-id` of the item"
  attr :preferences_label, :string, required: true
  attr :preferences_event, :any, default: nil
  attr :all_label, :string, required: true, doc: "the text of the \"see all\" action"
  attr :all_event, :any, default: nil

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "what goes in the tile of an item; gets the item"

  @doc "The notification panel."
  @spec panel(map()) :: Phoenix.LiveView.Rendered.t()
  def panel(assigns) do
    assigns = assign(assigns, :any_unread, any_unread?(assigns.groups))

    ~H"""
    <section
      id={@id}
      aria-labelledby={@id <> "-title"}
      phx-hook="DevactionUI.NotificationCenter"
      class={["notif", @class]}
      {@rest}
    >
      <div class="flex items-center gap-3 px-4 pt-4">
        <h2 id={@id <> "-title"} class="text-[17px] font-semibold">{@title}</h2>
        <button
          type="button"
          class="notif-readall ms-auto"
          disabled={!@any_unread}
          phx-click={@read_all_event}
          phx-target={@target}
        >
          {@read_all_label}
        </button>
      </div>
      <div
        role="tablist"
        aria-label={@tabs_label}
        class="mt-3 flex gap-4 border-b border-line-soft px-4"
      >
        <button
          :for={tab <- @tabs}
          type="button"
          role="tab"
          id={"#{@id}-tab-#{tab.id}"}
          aria-selected={to_string(tab.id == @tab)}
          aria-controls={@id <> "-list"}
          tabindex={tab_index(tab.id, @tab)}
          class="notif-tab"
          phx-click={@tab_event}
          phx-value-id={tab.id}
          phx-target={@target}
        >
          {tab.label}
          <span :if={count?(tab)} class="notif-count">{tab.count}</span>
        </button>
      </div>
      <div
        role="tabpanel"
        id={@id <> "-list"}
        aria-labelledby={"#{@id}-tab-#{@tab}"}
        class="max-h-[520px] overflow-auto"
      >
        <div :for={group <- @groups} role="group" aria-labelledby={"#{@id}-day-#{group.id}"}>
          <h3 id={"#{@id}-day-#{group.id}"} class="notif-day">{group.label}</h3>
          <ul class="m-0 list-none p-0">
            <li :for={item <- group.items}>
              <button
                type="button"
                id={"#{@id}-item-#{item.id}"}
                data-notification
                data-unread={to_string(item.unread)}
                class="notif-row"
                phx-click={@open_event}
                phx-value-id={item.id}
                phx-target={@target}
              >
                <span
                  class={["notif-tile", Tone.bg(item.tone), Tone.text(item.tone)]}
                  aria-hidden="true"
                >
                  {render_slot(@icon, item)}
                </span>
                <span class="min-w-0 flex-1">
                  <span class={[
                    "block text-sm leading-[1.45]",
                    (item.unread && "font-medium") || "font-normal"
                  ]}>
                    {item.title}
                  </span>
                  <span class="mt-[3px] block text-xs text-muted">{item.meta}</span>
                </span>
                <span :if={item.unread} class="notif-dot" role="img" aria-label={@unread_label}></span>
              </button>
            </li>
          </ul>
        </div>
        <p :if={@groups == []} class="px-4 py-10 text-center text-sm text-muted">{@empty_label}</p>
      </div>
      <div class="notif-foot">
        <button
          type="button"
          class="rounded-md text-ink-2 outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          phx-click={@preferences_event}
          phx-target={@target}
        >
          {@preferences_label}
        </button>
        <button
          type="button"
          class="rounded-md font-medium text-ink outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          phx-click={@all_event}
          phx-target={@target}
        >
          {@all_label}
        </button>
      </div>
    </section>
    """
  end

  defp any_unread?(groups),
    do: Enum.any?(groups, &Enum.any?(&1.items, fn item -> item.unread end))

  defp count?(%{count: count}) when is_integer(count) and count > 0, do: true
  defp count?(_tab), do: false

  defp tab_index(id, id), do: "0"
  defp tab_index(_id, _selected), do: "-1"
end
