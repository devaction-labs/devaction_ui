defmodule DevactionUI.Tabs do
  @moduledoc """
  Tabs that switch panels without a round trip: `variant: :boxed` is the pill group, `:line` the underlined
  row. A small hook moves the selection with ← → Home End (roving `tabindex`, `aria-selected`) and shows
  the panel of the selected tab. With `orientation: :vertical` the tabs are a column beside the panels, the
  list says `aria-orientation="vertical"` and the keys are ↑ ↓ Home End. Each tab may carry a `count`, in a `count_tone` if it should stand out.

  The first tab is selected unless one says `selected`. What the person picks in the browser survives the
  server re-rendering the tabs; when the server changes which tab says `selected`, that one wins. The dark
  theme uses the same tokens as the light one: the track is `wrap`, the selected tab is `card`.
  """
  use Phoenix.Component

  alias DevactionUI.Tone
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :variant, :atom, values: [:boxed, :line], default: :boxed
  attr :label, :string, required: true, doc: "the name of the tab list, for assistive technology"

  attr :orientation, :atom,
    values: [:horizontal, :vertical],
    default: :horizontal,
    doc: "`:vertical` puts the tabs in a column beside the panels"

  attr :full, :boolean,
    default: false,
    doc: "the tab list takes the whole width and the tabs share it"

  attr :size, :atom,
    values: [:md, :sm],
    default: :md,
    doc:
      "`:sm` is the 14px tab of a page inside an app, 40px high; it only changes the `:line` variant"

  attr :counts, :atom,
    values: [:plain, :chip],
    default: :plain,
    doc: "`:chip` draws the count of a tab in a small bordered box instead of plain mono text"

  attr :class, :any, default: nil

  slot :icon, doc: "the icon of a tab, 16px; gets `%{id: tab id}`"

  slot :tab,
    required: true,
    doc: "one tab; its content is the panel, and a tab with none has an empty panel" do
    attr :id, :string, required: true, doc: "names the tab and its panel; unique in the tabs"
    attr :label, :string, required: true
    attr :count, :any, doc: "a number beside the label"
    attr :count_tone, :atom, doc: "the tone of the count: risk, warn, ok, info or neutral"
    attr :selected, :boolean, doc: "open on first render, and whenever the server changes it"
  end

  attr :rest, :global

  @doc "Tabs that switch their panels in the browser."
  @spec tabs(map()) :: Phoenix.LiveView.Rendered.t()
  def tabs(assigns) do
    assigns = assign(assigns, :selected_id, selected_id(assigns.tab))

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Tabs"
      phx-mounted={JS.ignore_attributes(["data-selected"])}
      data-server-selected={@selected_id}
      class={[@orientation == :vertical && "flex items-start gap-6", @class]}
      {@rest}
    >
      <div
        role="tablist"
        aria-label={@label}
        aria-orientation={@orientation}
        class={list_class(@variant, @orientation, @full)}
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
          class={[
            "inline-flex shrink-0 items-center gap-2 whitespace-nowrap outline-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10",
            @full && "flex-1 justify-center",
            @orientation == :vertical && "justify-start",
            tab_class(@variant, @orientation, @size)
          ]}
        >
          <span :if={@icon != []} class="size-4 shrink-0 [&>*]:size-full" aria-hidden="true">
            {render_slot(@icon, %{id: tab.id})}
          </span>
          {tab.label}
          <span :if={Map.get(tab, :count)} class={["font-mono text-xs", count_class(tab, @counts)]}>
            {tab.count}
          </span>
        </button>
      </div>
      <div
        :for={tab <- @tab}
        role="tabpanel"
        id={"#{@id}-panel-#{tab.id}"}
        aria-labelledby={"#{@id}-tab-#{tab.id}"}
        hidden={tab.id != @selected_id}
        tabindex="0"
        class={panel_class(@orientation)}
      >
        {Map.get(tab, :inner_block) && render_slot(tab)}
      </div>
    </div>
    """
  end

  defp list_class(:boxed, orientation, full) do
    [
      "flex max-w-full gap-0.5 overflow-x-auto rounded-xl border border-line bg-wrap p-1 [scrollbar-width:none]",
      (orientation == :vertical && "flex-col") || (full && "w-full") || "w-fit"
    ]
  end

  defp list_class(:line, :horizontal, _full),
    do:
      "flex max-w-full gap-1 overflow-x-auto overflow-y-hidden shadow-[inset_0_-1px_0_var(--line)] [scrollbar-width:none]"

  defp list_class(:line, :vertical, _full), do: "flex flex-col gap-1 border-s border-line"

  defp tab_class(:boxed, _orientation, _size) do
    "h-[38px] rounded-[9px] text-ink-2 border border-transparent px-3.5 aria-selected:border-line aria-selected:bg-card aria-selected:font-medium aria-selected:text-ink"
  end

  defp tab_class(:line, :horizontal, size) do
    [
      "border-b-2 border-transparent px-3.5 text-muted focus-visible:ring-inset aria-selected:border-ink aria-selected:font-semibold aria-selected:text-ink",
      line_size(size)
    ]
  end

  defp tab_class(:line, :vertical, _size) do
    "-ms-px h-11 border-s-2 border-transparent px-3.5 text-muted aria-selected:border-ink aria-selected:font-semibold aria-selected:text-ink"
  end

  defp line_size(:md), do: "h-11"
  defp line_size(:sm), do: "h-10 text-sm"

  defp panel_class(:horizontal), do: "pt-4 outline-none"
  defp panel_class(:vertical), do: "min-w-0 flex-1 outline-none"

  defp count_class(%{count_tone: tone}, counts) when not is_nil(tone),
    do: [Tone.text(tone), chip(counts)]

  defp count_class(_tab, counts), do: ["text-muted", chip(counts)]

  defp chip(:chip), do: "rounded-md border border-line bg-wrap px-1.5 py-px leading-[18px]"
  defp chip(:plain), do: nil

  defp tab_index(id, id), do: "0"
  defp tab_index(_id, _selected), do: "-1"

  defp selected_id(tabs) do
    case Enum.find(tabs, &Map.get(&1, :selected, false)) || hd(tabs) do
      %{id: id} -> id
    end
  end
end
