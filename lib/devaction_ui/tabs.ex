defmodule DevactionUI.Tabs do
  @moduledoc """
  Tabs that switch panels without a round trip: `variant: :boxed` is the pill group, `:line` the underlined
  row. A small hook moves the selection with ← → Home End (roving `tabindex`, `aria-selected`) and shows
  the panel of the selected tab. Each tab may carry a `count`.

  The first tab is selected unless one says `selected`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :variant, :atom, values: [:boxed, :line], default: :boxed
  attr :label, :string, required: true, doc: "the name of the tab list, for assistive technology"

  attr :full, :boolean,
    default: false,
    doc: "the tab list takes the whole width and the tabs share it"

  attr :class, :any, default: nil

  slot :tab, required: true do
    attr :id, :string, required: true
    attr :label, :string, required: true
    attr :count, :any
    attr :selected, :boolean
  end

  attr :rest, :global

  def tabs(assigns) do
    assigns = assign(assigns, :selected_id, selected_id(assigns.tab))

    ~H"""
    <div id={@id} phx-hook="DevactionUI.Tabs" class={@class} {@rest}>
      <div
        role="tablist"
        aria-label={@label}
        class={[
          @variant == :boxed &&
            [
              "flex max-w-full gap-0.5 rounded-xl border border-line bg-wrap p-1",
              (@full && "w-full") || "w-fit"
            ],
          @variant == :line && "flex gap-1 border-b border-line"
        ]}
      >
        <button
          :for={tab <- @tab}
          type="button"
          role="tab"
          id={"#{@id}-tab-#{tab.id}"}
          aria-controls={"#{@id}-panel-#{tab.id}"}
          aria-selected={to_string(tab.id == @selected_id)}
          tabindex={tab_index(tab.id, @selected_id)}
          data-tab={tab.id}
          phx-mounted={JS.ignore_attributes(["aria-selected", "tabindex"])}
          class={[
            "inline-flex items-center gap-2 text-ink-2 outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
            @full && "flex-1 justify-center",
            @variant == :boxed &&
              "h-[38px] rounded-[9px] border border-transparent px-3.5 aria-selected:border-line aria-selected:bg-card aria-selected:font-medium aria-selected:text-ink",
            @variant == :line &&
              "-mb-px h-11 border-b-2 border-transparent px-3.5 text-muted aria-selected:border-ink aria-selected:font-semibold aria-selected:text-ink"
          ]}
        >
          {tab.label}
          <span :if={Map.get(tab, :count)} class="font-mono text-xs text-muted">{tab.count}</span>
        </button>
      </div>
      <div
        :for={tab <- @tab}
        role="tabpanel"
        id={"#{@id}-panel-#{tab.id}"}
        aria-labelledby={"#{@id}-tab-#{tab.id}"}
        hidden={tab.id != @selected_id}
        phx-mounted={JS.ignore_attributes(["hidden"])}
        tabindex="0"
        class="pt-4 outline-none"
      >
        {render_slot(tab)}
      </div>
    </div>
    """
  end

  defp tab_index(id, id), do: "0"
  defp tab_index(_id, _selected), do: "-1"

  defp selected_id(tabs) do
    case Enum.find(tabs, &Map.get(&1, :selected, false)) || hd(tabs) do
      %{id: id} -> id
    end
  end
end
