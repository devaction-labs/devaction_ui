defmodule DevactionUI.FileTree do
  @moduledoc """
  The tree of changed files of a review: folders and files with a status letter (added, modified, deleted), a
  badge with the number of findings, a header with the count and the lines added and removed, a search field,
  filter pills and a legend of the letters.

  The nodes come as data, a flat list in display order (`nodes`): `%{path: "lib/a.ex", type: :file, name:
  "a.ex", depth: 1, status: :modified, additions: 18, deletions: 6, findings: 2, level: :risk}`. A folder is
  `%{path: "lib", type: :dir}`; `name` and `depth` default to the last segment of the path and its depth, and
  a caller that compacts single-child folders (`lib/sge/` as one row) sets them itself. A node is shown when
  the folders above it are in `open`, so the server owns what is open, what is selected, the filter and the
  search text; the component only draws it. `visible/4` is that decision as a function, to use where the rows
  themselves are needed.

  Events, through attributes (a string or a `%JS{}`): `select_event` carries `path` when a file is pressed,
  `toggle_event` carries `path` when a folder is, `filter_event` carries `filter` (`"all"`, `"findings"` or
  `"new"`, the id of a `:pill` slot) and `search_event` carries `query` as the person types. While there is a
  search text every folder is shown open, so the matches are not hidden inside a closed folder.

  Keyboard (the `DevactionUI.FileTree` hook): ↑ ↓ Home End move the focus, → opens a closed folder or enters an
  open one, ← closes it or goes to the parent, Enter and Space press the item. Only one item is in the Tab
  order (roving `tabindex`). With `search_key` that key focuses the search field. Folders, files, the arrow and
  the search take their icons through slots; without them the arrow is a typographic `›`.
  """
  use Phoenix.Component

  @filters [:all, :findings, :new]

  @type node_data :: %{
          required(:path) => String.t(),
          required(:type) => :dir | :file,
          optional(:name) => String.t(),
          optional(:depth) => non_neg_integer(),
          optional(:status) => :added | :modified | :deleted | nil,
          optional(:additions) => non_neg_integer(),
          optional(:deletions) => non_neg_integer(),
          optional(:findings) => non_neg_integer(),
          optional(:level) => :risk | :warn
        }

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the tree for assistive technology"
  attr :title, :string, required: true, doc: "the heading of the panel, e.g. the files changed"

  attr :nodes, :list,
    required: true,
    doc: "the folders and files in display order; see the module documentation for the shape"

  attr :open, :list, default: [], doc: "the paths of the folders that are open"
  attr :selected, :string, default: nil, doc: "the path of the selected file"

  attr :filter, :atom,
    values: @filters,
    default: :all,
    doc: "which files show: all, those with findings or the new ones"

  attr :query, :string, default: "", doc: "the search text; files whose path contains it show"

  attr :search_label, :string,
    required: true,
    doc: "the name and the placeholder of the search field"

  attr :search_key, :string,
    default: nil,
    doc: "a key that focuses the search field when the person is not typing, e.g. `\"t\"`"

  attr :filters_label, :string,
    default: nil,
    doc: "the name of the group of filter pills for assistive technology"

  attr :findings_label, :string,
    default: nil,
    doc: "names the findings badge, as in `\"%{count} findings\"`"

  attr :letters, :map,
    default: %{added: "A", modified: "M", deleted: "D"},
    doc: "the letter of each status"

  attr :select_event, :any, default: "select_file", doc: "sent with `path` when a file is pressed"
  attr :toggle_event, :any, default: "toggle_folder", doc: "sent with `path` when a folder is"
  attr :filter_event, :any, default: "filter_files", doc: "sent with `filter` when a pill is"
  attr :search_event, :any, default: "search_files", doc: "sent with `query` as the person types"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :pill, doc: "one filter pill" do
    attr :id, :atom, required: true, doc: "`:all`, `:findings` or `:new`"
    attr :label, :string, required: true
  end

  slot :legend, doc: "one entry of the legend of status letters" do
    attr :status, :atom, required: true, doc: "`:added`, `:modified` or `:deleted`"
    attr :label, :string, required: true
  end

  slot :search_hint, doc: "the shortcut shown at the end of the search field, e.g. `T`"
  slot :empty, doc: "what shows when no file matches"
  slot :search_icon, doc: "the icon of the search field"
  slot :folder_icon, doc: "the icon of a folder"
  slot :file_icon, doc: "the icon of a file"
  slot :chevron_icon, doc: "the arrow of a folder; it turns when the folder opens"

  @doc "The tree of changed files."
  @spec tree(map()) :: Phoenix.LiveView.Rendered.t()
  def tree(assigns) do
    rows = visible(assigns.nodes, assigns.open, assigns.filter, assigns.query)
    files = assigns.nodes |> Enum.map(&normalize/1) |> Enum.filter(&(&1.type == :file))
    totals = totals(assigns.nodes)

    assigns =
      assign(assigns,
        rows: rows,
        stop: stop(rows, assigns.selected),
        open_set: MapSet.new(assigns.open),
        count: length(files),
        additions: totals.additions,
        deletions: totals.deletions
      )

    ~H"""
    <aside
      id={@id}
      aria-label={@label}
      phx-hook="DevactionUI.FileTree"
      data-file-tree
      data-stop={@stop}
      data-search-key={@search_key}
      class={["flex min-h-0 flex-col text-ink", @class]}
      {@rest}
    >
      <div class="border-b border-line-soft px-3.5 pt-3.5 pb-2.5">
        <div class="flex items-center gap-2">
          <span class="text-sm font-semibold">{@title}</span>
          <span class="font-mono text-[11px] text-muted">{@count}</span>
          <span class="ml-auto font-mono text-[11px]">
            <span class="text-tag-ok-text">+{@additions}</span>
            <span class="text-tag-risk-text">−{@deletions}</span>
          </span>
        </div>
        <form
          id={"#{@id}-search"}
          phx-change={@search_event}
          phx-submit={@search_event}
          phx-target={@target}
          class="mt-2.5"
        >
          <label class="flex h-8 items-center gap-2 rounded-lg border border-line px-2.5 text-[13px] text-muted focus-within:ring-4 focus-within:ring-ink/10">
            <span :if={@search_icon != []} aria-hidden="true" class="flex size-3.5 shrink-0">
              {render_slot(@search_icon)}
            </span>
            <input
              type="search"
              name="query"
              value={@query}
              placeholder={@search_label}
              aria-label={@search_label}
              autocomplete="off"
              phx-debounce="150"
              data-tree-search
              class="min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-[13px] text-ink outline-none placeholder:text-muted"
            />
            <kbd
              :if={@search_hint != []}
              class="rounded border border-line px-[5px] py-px font-mono text-[10px]"
            >
              {render_slot(@search_hint)}
            </kbd>
          </label>
        </form>
        <div :if={@pill != []} role="group" aria-label={@filters_label} class="mt-2 flex gap-1">
          <button
            :for={pill <- @pill}
            type="button"
            aria-pressed={to_string(pill.id == @filter)}
            phx-click={@filter_event}
            phx-target={@target}
            phx-value-filter={pill.id}
            class={[
              "h-[26px] cursor-pointer rounded-[7px] border px-2 text-xs outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
              pill_class(pill.id == @filter)
            ]}
          >
            {pill.label}
          </button>
        </div>
      </div>
      <div role="tree" aria-label={@label} class="min-h-0 flex-1 overflow-auto p-1.5 text-[13px]">
        <button
          :for={node <- @rows}
          type="button"
          role="treeitem"
          id={"#{@id}:#{node.path}"}
          data-path={node.path}
          aria-level={node.depth + 1}
          aria-expanded={expanded(node, @open_set, @query)}
          aria-selected={to_string(node.path == @selected)}
          tabindex={tab_index(node.path, @stop)}
          phx-click={click_event(node, @select_event, @toggle_event)}
          phx-target={@target}
          phx-value-path={node.path}
          style={"padding-inline-start: #{8 + min(node.depth, 6) * 16}px"}
          class={[
            "flex h-[30px] w-full cursor-pointer items-center gap-1.5 rounded-[7px] border-0 bg-transparent pe-2 text-start text-[13px] text-ink outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20",
            node.path == @selected && "bg-wrap font-semibold"
          ]}
        >
          <span
            data-chevron
            aria-hidden="true"
            class={[
              "flex size-3 shrink-0 items-center justify-center text-muted transition-transform",
              node.type == :file && "invisible",
              open?(node, @open_set, @query) && "rotate-90"
            ]}
          >
            {render_slot(@chevron_icon) || "›"}
          </span>
          <span
            aria-hidden="true"
            class={[
              "flex size-[15px] shrink-0 items-center justify-center",
              (node.type == :dir && "text-tree-folder") || "text-muted"
            ]}
          >
            {(node.type == :dir && render_slot(@folder_icon)) || render_slot(@file_icon)}
          </span>
          <span class={[
            "min-w-0 overflow-hidden text-ellipsis whitespace-nowrap",
            node.status == :deleted && "text-muted"
          ]}>
            {node.name}
          </span>
          <span class="ml-auto flex shrink-0 items-center gap-1.5">
            <span
              :if={node.findings > 0}
              aria-label={fill_label(@findings_label, node.findings)}
              class={[
                "inline-flex h-[18px] min-w-[18px] items-center justify-center rounded-full px-[5px] text-[11px] font-semibold text-on-finding",
                level_class(node.level)
              ]}
            >
              {node.findings}
            </span>
            <span
              :if={node.status}
              aria-label={legend_label(@legend, node.status)}
              class={[
                "inline-flex size-3.5 items-center justify-center rounded-[3px] font-mono text-[10px]",
                status_class(node.status)
              ]}
            >
              {Map.fetch!(@letters, node.status)}
            </span>
          </span>
        </button>
        <p :if={@rows == [] and @empty != []} class="px-2 py-3 text-[13px] text-muted">
          {render_slot(@empty)}
        </p>
      </div>
      <div
        :if={@legend != []}
        class="flex gap-3 border-t border-line-soft px-3.5 py-2.5 text-[11px] text-muted"
      >
        <span :for={entry <- @legend} class="flex items-center gap-1">
          <span
            aria-hidden="true"
            class={[
              "inline-flex size-3 items-center justify-center rounded-[3px] font-mono text-[9px]",
              status_class(entry.status)
            ]}
          >
            {Map.fetch!(@letters, entry.status)}
          </span>
          {entry.label}
        </span>
      </div>
    </aside>
    """
  end

  @doc """
  The nodes that show: files that pass the `filter` (`:all`, `:findings` or `:new`) and whose path contains
  `query` (ignoring case), the folders that hold one of them (every folder when nothing filters), and only
  those whose folders above are in `open`; with a `query` every folder counts as open. Each node comes with its
  defaults filled in.
  """
  @spec visible([node_data()], [String.t()], :all | :findings | :new, String.t()) :: [map()]
  def visible(nodes, open, filter \\ :all, query \\ "") when filter in @filters do
    nodes = Enum.map(nodes, &normalize/1)
    dirs = for %{type: :dir, path: path} <- nodes, into: MapSet.new(), do: path
    kept = for %{type: :file} = node <- nodes, passes?(node, filter, query), do: node.path

    context = %{
      dirs: dirs,
      open: MapSet.new(open),
      kept: kept,
      filtering?: filtering?(filter, query),
      query: query
    }

    Enum.filter(nodes, &(kept?(&1, context) and ancestors_open?(&1.path, context)))
  end

  @doc "The lines added and removed by the files of the nodes: `%{additions: 24, deletions: 9}`."
  @spec totals([node_data()]) :: %{additions: non_neg_integer(), deletions: non_neg_integer()}
  def totals(nodes) do
    files = nodes |> Enum.map(&normalize/1) |> Enum.filter(&(&1.type == :file))

    %{
      additions: files |> Enum.map(& &1.additions) |> Enum.sum(),
      deletions: files |> Enum.map(& &1.deletions) |> Enum.sum()
    }
  end

  defp normalize(%{type: type, path: path} = node) do
    Map.merge(
      %{
        name: default_name(type, path),
        depth: path |> Path.split() |> length() |> Kernel.-(1),
        status: nil,
        additions: 0,
        deletions: 0,
        findings: 0,
        level: :warn
      },
      node
    )
  end

  defp default_name(:dir, path), do: Path.basename(path) <> "/"
  defp default_name(:file, path), do: Path.basename(path)

  defp filtering?(:all, ""), do: false
  defp filtering?(_filter, _query), do: true

  defp passes?(node, filter, query), do: filter_ok?(node, filter) and matches?(node.path, query)

  defp filter_ok?(_node, :all), do: true
  defp filter_ok?(%{findings: findings}, :findings), do: findings > 0
  defp filter_ok?(%{status: status}, :new), do: status == :added

  defp matches?(path, query), do: String.contains?(String.downcase(path), String.downcase(query))

  defp kept?(%{type: :file, path: path}, %{kept: kept}), do: path in kept
  defp kept?(%{type: :dir}, %{filtering?: false}), do: true

  defp kept?(%{type: :dir, path: path}, %{kept: kept}),
    do: Enum.any?(kept, &String.starts_with?(&1, path <> "/"))

  defp ancestors_open?(_path, %{query: query}) when query != "", do: true

  defp ancestors_open?(path, %{dirs: dirs, open: open}) do
    path
    |> prefixes()
    |> Enum.filter(&MapSet.member?(dirs, &1))
    |> Enum.all?(&MapSet.member?(open, &1))
  end

  defp prefixes(path) do
    parts = path |> Path.split() |> Enum.drop(-1)
    for count <- 1..length(parts)//1, do: parts |> Enum.take(count) |> Enum.join("/")
  end

  defp stop(rows, selected) do
    case Enum.find(rows, &(&1.path == selected)) || List.first(rows) do
      nil -> nil
      %{path: path} -> path
    end
  end

  defp tab_index(path, path), do: "0"
  defp tab_index(_path, _stop), do: "-1"

  defp click_event(%{type: :dir}, _select, toggle), do: toggle
  defp click_event(%{type: :file}, select, _toggle), do: select

  defp open?(%{type: :dir, path: path}, open, ""), do: MapSet.member?(open, path)
  defp open?(%{type: :dir}, _open, _query), do: true
  defp open?(%{type: :file}, _open, _query), do: false

  defp expanded(%{type: :file}, _open, _query), do: nil
  defp expanded(node, open, query), do: to_string(open?(node, open, query))

  defp pill_class(true), do: "border-ink bg-ink text-on-ink"
  defp pill_class(false), do: "border-line bg-card text-ink-2 hover:bg-wrap"

  defp level_class(:risk), do: "bg-finding-risk"
  defp level_class(:warn), do: "bg-ai"

  defp status_class(:added), do: "bg-tag-ok-bg text-tag-ok-text"
  defp status_class(:modified), do: "bg-tag-warn-bg text-tag-warn-text"
  defp status_class(:deleted), do: "bg-tag-risk-bg text-tag-risk-text"

  defp fill_label(nil, _count), do: nil
  defp fill_label(label, count), do: String.replace(label, "%{count}", to_string(count))

  defp legend_label(legend, status) do
    Enum.find_value(legend, fn
      %{status: ^status, label: label} -> label
      _entry -> nil
    end)
  end
end
