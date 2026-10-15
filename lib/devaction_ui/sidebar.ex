defmodule DevactionUI.Sidebar do
  @moduledoc """
  The side menu of an app: 236 px wide, or 64 px when collapsed, where each item keeps its icon and shows its
  name in a tooltip on hover and on keyboard focus. The current item has `aria-current="page"`. The caller keeps
  whether it is collapsed (`collapsed`) and gets the press of the toggle in `on_toggle`; it is hidden on small
  screens, where the app has its own navigation.
  """
  use Phoenix.Component

  attr :id, :string, required: true

  attr :label, :string,
    required: true,
    doc: "the name of the navigation, for assistive technology"

  attr :collapsed, :boolean, default: false

  attr :on_toggle, :string,
    default: nil,
    doc: "the event of the button that collapses and opens it"

  attr :toggle_label, :string,
    default: nil,
    doc: "what the toggle button does, read by assistive technology"

  attr :class, :any, default: nil
  slot :toggle_icon
  slot :header, doc: "the brand or the workspace, above the items"
  slot :footer, doc: "what stays at the bottom: the person, a help link"

  slot :item, required: true do
    attr :to, :string, required: true
    attr :label, :string, required: true
    attr :current, :boolean
    attr :count, :any
  end

  slot :icon, doc: "the icon of an item; gets `%{label: item label}`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def sidebar(assigns) do
    ~H"""
    <nav
      id={@id}
      aria-label={@label}
      data-collapsed={to_string(@collapsed)}
      class={["sidebar", @class]}
      {@rest}
    >
      <div :if={@header != []} class="flex items-center gap-2.5 px-1">{render_slot(@header)}</div>
      <ul class="m-0 flex list-none flex-col gap-1 p-0">
        <li :for={item <- @item} class="group/tip relative">
          <.link
            navigate={item.to}
            aria-current={Map.get(item, :current) && "page"}
            aria-label={@collapsed && item.label}
            class="sidebar-link no-underline outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            <span class="size-5 shrink-0">{render_slot(@icon, %{label: item.label})}</span>
            <span :if={!@collapsed} class="flex-1 truncate">{item.label}</span>
            <span
              :if={!@collapsed and Map.get(item, :count)}
              class="rounded-md bg-wrap px-1.5 font-mono text-[11px] text-muted"
            >
              {item.count}
            </span>
          </.link>
          <span
            :if={@collapsed}
            role="tooltip"
            class="pointer-events-none absolute top-1/2 left-full z-50 ml-2 -translate-y-1/2 rounded-lg bg-ink px-2.5 py-1.5 text-xs whitespace-nowrap text-on-primary opacity-0 shadow-lg transition-opacity group-hover/tip:opacity-100 group-focus-within/tip:opacity-100 motion-reduce:transition-none"
          >
            {item.label}
          </span>
        </li>
      </ul>
      <div class="mt-auto flex flex-col gap-2">
        {render_slot(@footer)}
        <button
          :if={@on_toggle}
          id={"#{@id}-toggle"}
          type="button"
          aria-label={@toggle_label}
          aria-expanded={to_string(!@collapsed)}
          phx-click={@on_toggle}
          phx-target={@target}
          class="sidebar-link outline-none focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          <span class="size-5 shrink-0">{render_slot(@toggle_icon)}</span>
        </button>
      </div>
    </nav>
    """
  end
end
