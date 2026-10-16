defmodule DevactionUI.DataTable do
  @moduledoc """
  A table for lists that are worked on: sticky header, sortable columns (`aria-sort`, the server sorts and
  the table only draws the arrows), optional row selection with a tri-state header checkbox and a bulk
  bar that appears while something is selected, two densities, and the states of a list: loading, error and
  empty.

  `rows` is a list, or a stream (`stream(socket, :rows, rows)`) when the table is long: then the body is a
  `phx-update="stream"` and the empty state shows on its own when the stream is empty.

  The columns are `:col` slots (`label`, `key`, `sortable`, `class`), each given the row with `:let`.
  Selection is the browser's: the checkboxes are plain inputs named `name[]`, a hook keeps the header
  checkbox and the bulk bar in step, and fires `input` on the table so a form around it hears the change.

  `selected` is the list of row ids ticked when the table is first drawn; after that the browser owns the
  ticks. A column with no title of its own (the actions of a row) takes `hide_label`: its `label` stays for
  screen readers and is not drawn. The arrows of a sorted header are the `sort_asc_icon`, `sort_desc_icon` and
  `sort_none_icon` slots (a typographic arrow when empty).

  Texts (`select_all_label`, `select_row_label`, `selected_label` with `__COUNT__`, `clear_label`) come
  from the caller, so the library carries no language of its own.

  Around the rows: the `toolbar` slot sits above the table (a search, filter chips, the columns menu) and the
  `footer` slot below it, for the range of the page ("1-6 of 33") and a `DevactionUI.Pagination`. With
  `density_label` the toolbar ends with a toggle that switches between the two densities in the browser (`density`
  is where it starts; the choice is kept across redraws), its icon the `density_icon` slot. `max_height` is a class
  written in full, so the Tailwind of the app finds it through the `@source` of this package.

  A `:col` with `sticky={:start}` (the first column) or `sticky={:end}` (the actions) stays in view while the table
  scrolls sideways; in a selectable table the checkbox column is pinned along with the first one. The header is
  always sticky, and a table with pinned columns gets a shadow on the pinned side only while there is content
  behind it (the `DevactionUI.ScrollArea` hook).

  `loading` draws `loading_rows` rows of skeletons in place of the rows (named once for assistive technology by
  `loading_label`, which it needs) and `error` draws its message, with the `error_action` slot for a retry button,
  as an alert; the empty state is the `empty` slot, or the text `empty_text`. In a stream the rows stay in the page
  while one of these shows, hidden.

  Variations, which add up:

    * `variant` is `:default` (a border and a grey head) or `:minimal` (no border, a transparent head in sentence
      case: for a table inside a card or a panel); `density={:compact}` and `striped` thin and band the rows.
    * the `expanded` slot is a detail row opened by a chevron at the start of the row (`aria-expanded`; the
      browser toggles it and a redraw keeps it open); `expand_label` names the button and is required with it.
    * `group_by` is a function row -> key; consecutive rows with the same key sit under a group row drawn by the
      `group` slot, which is given `{key, rows}`.
    * the `tfoot` slot is the totals row (give it a `<tr>`), the `footer` slot sits below the table.
    * `stack` turns each row into a card under 640px: the `primary` column is the title of the card and the
      other cells carry their column `label` as a caption.
    * the `action` slot is the last cell of a row, the `⋯` menu with no box of its own (`action_label` names the
      column and is required with it); `sticky_actions` pins it to the end while the table scrolls sideways.
    * a `:col` takes `align` (`:start`, `:center`, `:end`) and `mono` for figures.
    * Shift+click on a row checkbox ticks every row between it and the last one clicked.

  `expanded` and `group_by` need `rows` to be a list: a stream holds one element per row.
  """
  use Phoenix.Component

  import DevactionUI.Skeleton, only: [skeleton: 1]

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "what the table lists, for assistive technology"

  attr :rows, :any,
    required: true,
    doc: "a list, or a `Phoenix.LiveView.LiveStream` for a long table"

  attr :row_id, :any, default: &DevactionUI.DataTable.default_id/1, doc: "a function: row -> id"
  attr :sort, :any, default: nil, doc: "`{key, :asc | :desc}` or nil"

  attr :on_sort, :string,
    default: nil,
    doc: "the event sent with `phx-value-key` when a header is clicked"

  attr :variant, :atom,
    values: [:default, :minimal],
    default: :default,
    doc: "`:minimal` has no border and a transparent head, for a table inside a card"

  attr :striped, :boolean, default: false, doc: "bands every other row"

  attr :stack, :boolean,
    default: false,
    doc: "under 640px each row becomes a card; the `primary` column is its title"

  attr :group_by, :any,
    default: nil,
    doc:
      "a function: row -> key; consecutive rows with one key sit under a group row (needs a list)"

  attr :selectable, :boolean, default: false
  attr :name, :string, default: "selected", doc: "the field name of the row checkboxes (`name[]`)"

  attr :density, :atom,
    values: [:comfortable, :compact],
    default: :comfortable,
    doc: "the density the table starts in"

  attr :density_label, :string,
    default: nil,
    doc: "names the density toggle at the end of the toolbar; without it there is no toggle"

  attr :loading, :boolean, default: false, doc: "draws skeleton rows instead of the rows"
  attr :loading_rows, :integer, default: 5, doc: "how many skeleton rows"

  attr :loading_label, :string,
    default: nil,
    doc: "what is loading, read once by screen readers; required when `loading`"

  attr :error, :string, default: nil, doc: "a message that replaces the rows, drawn as an alert"
  attr :empty_text, :string, default: nil, doc: "what the empty state says when it has no slot"
  attr :selected, :list, default: [], doc: "the ids of the rows ticked at the first draw"

  attr :max_height, :string,
    default: "max-h-[300px]",
    doc: "a Tailwind class; it is only found if it is written in the app's own sources"

  attr :sticky_actions, :boolean,
    default: false,
    doc: "pins the cell of the `action` slot to the end while the table scrolls sideways"

  attr :action_label, :string,
    default: nil,
    doc: "names the column of the `action` slot for assistive technology; required with it"

  attr :expand_label, :string,
    default: nil,
    doc: "names the chevron that opens a detail row; required with the `expanded` slot"

  attr :select_all_label, :string, required: true
  attr :select_row_label, :string, required: true
  attr :selected_label, :string, required: true, doc: "with `__COUNT__`"
  attr :clear_label, :string, required: true
  attr :class, :any, default: nil

  slot :col, required: true do
    attr :label, :string, required: true
    attr :key, :string
    attr :sortable, :boolean
    attr :hide_label, :boolean, doc: "keep the label for screen readers only"
    attr :class, :string
    attr :primary, :boolean, doc: "the title of the card when the table is a `stack`"
    attr :mono, :boolean, doc: "figures in the mono face"

    attr :align, :atom,
      values: [:start, :center, :end],
      doc: "where the text of the column sits; `:end` for numbers"

    attr :sticky, :atom,
      values: [:start, :end],
      doc:
        "pins the column to the start (the first column) or the end (the actions) while the table scrolls sideways"
  end

  slot :sort_asc_icon, doc: "the arrow of the column sorted ascending"
  slot :sort_desc_icon, doc: "the arrow of the column sorted descending"
  slot :sort_none_icon, doc: "the arrow of a sortable column that is not sorted"
  slot :expand_icon, doc: "the chevron of the button that opens a detail row (it turns when open)"

  slot :action, doc: "the last cell of a row, given the row: the `⋯` menu, with no box of its own"
  slot :expanded, doc: "the detail row under a row, given the row; opened by a chevron"
  slot :group, doc: "the content of a group row, given `{key, rows}`; required with `group_by`"
  slot :tfoot, doc: "the totals: a `<tr>` in the foot of the table"
  slot :bulk, doc: "the actions of the bulk bar"
  slot :empty, doc: "shown when there are no rows"
  slot :toolbar, doc: "above the table: a search, filter chips, a menu of columns"
  slot :footer, doc: "below the table: the range of the page and a pagination"
  slot :density_icon, doc: "the icon of the density toggle"
  slot :error_action, doc: "under the error: a retry button"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def data_table(%{loading: true, loading_label: nil}),
    do: raise(ArgumentError, "data_table/1 needs a loading_label while it is loading")

  def data_table(%{action: [_ | _], action_label: nil}),
    do: raise(ArgumentError, "data_table/1 needs an action_label with the action slot")

  def data_table(%{expanded: [_ | _], expand_label: nil}),
    do: raise(ArgumentError, "data_table/1 needs an expand_label with the expanded slot")

  def data_table(%{group_by: group_by, group: []}) when group_by != nil,
    do: raise(ArgumentError, "data_table/1 needs a group slot with group_by")

  def data_table(%{rows: %Phoenix.LiveView.LiveStream{}, expanded: [_ | _]}),
    do: raise(ArgumentError, "data_table/1 draws the expanded slot only for a list of rows")

  def data_table(%{rows: %Phoenix.LiveView.LiveStream{}, group_by: group_by})
      when group_by != nil,
      do: raise(ArgumentError, "data_table/1 draws group_by only for a list of rows")

  def data_table(assigns) do
    assigns =
      assign(assigns,
        entries: entries(assigns.rows, assigns.row_id, assigns.id, assigns.group_by),
        streaming: streaming?(assigns.rows),
        ticked: MapSet.new(assigns.selected, &to_string/1),
        pinned: assigns.sticky_actions or Enum.any?(assigns.col, &(Map.get(&1, :sticky) != nil)),
        pin_select: Enum.any?(assigns.col, &(Map.get(&1, :sticky) == :start)),
        end_sticky: assigns.sticky_actions && "end",
        ncols: columns(assigns)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DataTable"
      data-selected-label={@selected_label}
      data-density={@density}
      data-variant={@variant}
      data-striped={@striped}
      data-stack={@stack}
      class={["data-table-root group/dt flex flex-col gap-2", @class]}
      {@rest}
    >
      <div :if={@toolbar != [] or @density_label} class="flex flex-wrap items-center gap-2">
        {render_slot(@toolbar)}
        <button
          :if={@density_label}
          type="button"
          data-density-toggle
          aria-label={@density_label}
          aria-pressed={to_string(@density == :compact)}
          class="ml-auto grid size-9 place-items-center rounded-[10px] border border-line-strong bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 aria-pressed:bg-wrap aria-pressed:text-ink"
        >
          {(@density_icon != [] && render_slot(@density_icon)) || "≡"}
        </button>
      </div>
      <p :if={@loading} role="status" class="sr-only">{@loading_label}</p>
      <div
        :if={@selectable}
        data-bulk
        hidden
        class="flex flex-wrap items-center gap-3 rounded-xl bg-ink px-3.5 py-2.5 text-sm text-on-primary"
        role="status"
      >
        <span data-count class="font-medium"></span>
        <span class="h-4 w-px bg-on-primary/25" aria-hidden="true" />
        <div class="flex flex-wrap items-center gap-2 [&>*]:inline-flex [&>*]:h-8 [&>*]:items-center [&>*]:rounded-lg [&>*]:border-transparent! [&>*]:bg-on-primary/15 [&>*]:px-3 [&>*]:text-on-primary! [&>*]:text-[13px] [&>*]:outline-none hover:[&>*]:bg-on-primary/25 focus-visible:[&>*]:ring-2 focus-visible:[&>*]:ring-white/40">
          {render_slot(@bulk)}
        </div>
        <button
          type="button"
          data-clear
          class="ml-auto rounded-lg px-2.5 py-1 text-[13px] opacity-80 outline-none hover:opacity-100 focus-visible:ring-2 focus-visible:ring-white/40"
        >
          {@clear_label}
        </button>
      </div>

      <div
        id={@pinned && "#{@id}-scroll"}
        class={[
          "overflow-auto rounded-xl border border-line bg-card outline-none focus-visible:ring-2 focus-visible:ring-ink/40 focus-visible:ring-inset group-data-[variant=minimal]/dt:rounded-none group-data-[variant=minimal]/dt:border-0 group-data-[variant=minimal]/dt:bg-transparent",
          @max_height
        ]}
        data-pinned={@pinned && ""}
        role="region"
        tabindex="0"
        aria-label={@label}
        phx-hook={@pinned && "DevactionUI.ScrollArea"}
        phx-mounted={@pinned && JS.ignore_attributes(edge_attributes())}
      >
        <table
          class="data-table w-full border-collapse text-left text-sm"
          aria-busy={@loading && "true"}
        >
          <caption class="sr-only">{@label}</caption>
          <thead>
            <tr>
              <th
                :if={@selectable}
                scope="col"
                class={[th(), "w-10"]}
                data-select-cell
                data-sticky={@pin_select && "start"}
              >
                <input
                  type="checkbox"
                  data-select-all
                  aria-label={@select_all_label}
                  class="checkbox"
                />
              </th>
              <th :if={@expanded != []} scope="col" class={[th(), "w-11"]} data-expand-cell>
                <span class="sr-only">{@expand_label}</span>
              </th>
              <th
                :for={col <- @col}
                scope="col"
                data-sticky={Map.get(col, :sticky)}
                data-align={Map.get(col, :align)}
                aria-sort={sort_state(col, @sort)}
                class={[th(), Map.get(col, :class)]}
              >
                <button
                  :if={Map.get(col, :sortable, false) && @on_sort}
                  type="button"
                  phx-click={@on_sort}
                  phx-target={@target}
                  phx-value-key={col.key}
                  class={[
                    "inline-flex items-center gap-1 font-mono text-[11px] font-medium uppercase tracking-[0.08em] outline-none hover:text-ink focus-visible:text-ink",
                    minimal_head(),
                    sorted?(col, @sort) && "text-ink"
                  ]}
                >
                  {col.label}
                  <span aria-hidden="true">
                    <.sort_icon
                      dir={direction(col, @sort)}
                      asc={@sort_asc_icon}
                      desc={@sort_desc_icon}
                      none={@sort_none_icon}
                    />
                  </span>
                </button>
                <span
                  :if={!(Map.get(col, :sortable, false) && @on_sort)}
                  class={Map.get(col, :hide_label, false) && "sr-only"}
                >
                  {col.label}
                </span>
              </th>
              <th
                :if={@action != []}
                scope="col"
                class={[th("px-2"), "w-[52px]"]}
                data-actions
                data-sticky={@end_sticky}
              >
                <span class="sr-only">{@action_label}</span>
              </th>
            </tr>
          </thead>
          <tbody
            id={"#{@id}-body"}
            phx-update={@streaming && "stream"}
            hidden={@loading or @error != nil}
          >
            <.entry
              :for={entry <- @entries}
              entry={entry}
              col={@col}
              action={@action}
              expanded={@expanded}
              group={@group}
              expand_icon={@expand_icon}
              expand_label={@expand_label}
              selectable={@selectable}
              pin_select={@pin_select}
              end_sticky={@end_sticky}
              name={@name}
              select_row_label={@select_row_label}
              row_id={@row_id}
              ticked={@ticked}
              ncols={@ncols}
            />
            <tr
              :if={@streaming or @entries == []}
              id={"#{@id}-empty"}
              class={@streaming && "hidden only:table-row"}
            >
              <td colspan={@ncols} class="px-4 py-8 text-center text-muted">
                {(@empty != [] && render_slot(@empty)) || @empty_text}
              </td>
            </tr>
          </tbody>
          <tbody :if={@loading} aria-hidden="true">
            <tr :for={row <- 1..max(@loading_rows, 1)//1}>
              <td :if={@selectable} class={[td(), "w-10"]}>
                <.skeleton class="size-5 rounded-md" />
              </td>
              <td :if={@expanded != []} class={[td(), "w-11"]}></td>
              <td :for={{_col, at} <- Enum.with_index(@col)} class={td()}>
                <.skeleton class={bar_width(row + at)} />
              </td>
              <td :if={@action != []} class={td_action()} data-actions data-sticky={@end_sticky}></td>
            </tr>
          </tbody>
          <tbody :if={@error && !@loading}>
            <tr>
              <td colspan={@ncols} class="px-4 py-8 text-center">
                <div role="alert" class="flex flex-col items-center gap-3">
                  <span class="text-missing">{@error}</span>
                  {render_slot(@error_action)}
                </div>
              </td>
            </tr>
          </tbody>
          <tfoot :if={@tfoot != []}>{render_slot(@tfoot)}</tfoot>
        </table>
      </div>
      <div
        :if={@footer != []}
        class="flex flex-wrap items-center justify-between gap-3 text-[13px] text-muted"
      >
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  attr :entry, :any, required: true
  attr :col, :list, required: true
  attr :action, :list, required: true
  attr :expanded, :list, required: true
  attr :group, :list, required: true
  attr :expand_icon, :list, required: true
  attr :expand_label, :string, default: nil
  attr :selectable, :boolean, required: true
  attr :pin_select, :boolean, required: true
  attr :end_sticky, :any, default: nil
  attr :name, :string, required: true
  attr :select_row_label, :string, required: true
  attr :row_id, :any, required: true
  attr :ticked, :any, required: true
  attr :ncols, :integer, required: true

  defp entry(%{entry: {:group, key, rows}} = assigns) do
    assigns = assign(assigns, key: key, rows: rows)

    ~H"""
    <tr data-group-row>
      <td
        colspan={@ncols}
        class="h-[38px] border-b border-line-soft bg-wrap px-3 text-[13px] font-semibold"
      >
        {render_slot(@group, {@key, @rows})}
      </td>
    </tr>
    """
  end

  defp entry(%{entry: {dom_id, row}} = assigns) do
    assigns = assign(assigns, dom_id: dom_id, row: row, value: assigns.row_id.(row))

    ~H"""
    <tr
      id={@dom_id}
      data-row
      aria-selected={@selectable && to_string(selected?(@ticked, @value))}
      phx-mounted={@expanded != [] && JS.ignore_attributes(["data-open"])}
      class="group/row hover:bg-wrap has-[input:checked]:bg-ink/[.03]"
    >
      <td
        :if={@selectable}
        class={[td(), "w-10"]}
        data-select-cell
        data-sticky={@pin_select && "start"}
      >
        <input
          type="checkbox"
          data-select-row
          name={@name <> "[]"}
          value={@value}
          checked={selected?(@ticked, @value)}
          aria-label={@select_row_label}
          class="checkbox"
        />
      </td>
      <td :if={@expanded != []} class={[td(), "w-11 text-center"]} data-expand-cell>
        <button
          type="button"
          data-expand-toggle
          aria-expanded="false"
          aria-controls={@dom_id <> "-detail"}
          aria-label={@expand_label}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
          class="group/exp grid size-[26px] place-items-center rounded-lg text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          <span aria-hidden="true" class="transition-transform group-aria-expanded/exp:rotate-90">
            {(@expand_icon != [] && render_slot(@expand_icon)) || "›"}
          </span>
        </button>
      </td>
      <td
        :for={col <- @col}
        class={[td(), Map.get(col, :class)]}
        data-sticky={Map.get(col, :sticky)}
        data-align={Map.get(col, :align)}
        data-mono={Map.get(col, :mono)}
        data-primary={Map.get(col, :primary)}
        data-label={caption(col)}
      >
        {render_slot(col, @row)}
      </td>
      <td :if={@action != []} class={td_action()} data-actions data-sticky={@end_sticky}>
        {render_slot(@action, @row)}
      </td>
    </tr>
    <tr
      :if={@expanded != []}
      id={@dom_id <> "-detail"}
      data-expanded-row
      hidden
      phx-mounted={JS.ignore_attributes(["hidden"])}
    >
      <td
        colspan={@ncols}
        class="border-b border-line-soft bg-wrap py-3 pr-4 pl-14 whitespace-normal"
      >
        {render_slot(@expanded, @row)}
      </td>
    </tr>
    """
  end

  @doc false
  def default_id(%{id: id}), do: id

  defp edge_attributes,
    do: [
      "data-more-left",
      "data-more-right",
      "data-more-top",
      "data-more-bottom",
      "data-scrolled-y"
    ]

  defp th(px \\ "px-3"),
    do: [
      "sticky top-0 z-10 border-b border-line bg-card py-2.5 font-mono text-[11px] font-medium uppercase tracking-[0.08em] text-muted",
      minimal_head(),
      px
    ]

  defp minimal_head,
    do:
      "group-data-[variant=minimal]/dt:bg-transparent group-data-[variant=minimal]/dt:font-sans group-data-[variant=minimal]/dt:text-xs group-data-[variant=minimal]/dt:normal-case group-data-[variant=minimal]/dt:tracking-normal"

  defp td,
    do: "border-b border-line-soft px-3 py-3 align-middle group-data-[density=compact]/dt:py-1.5"

  defp td_action,
    do:
      "w-[52px] border-b border-line-soft px-2 py-3 text-right align-middle group-data-[density=compact]/dt:py-1.5"

  defp caption(%{primary: true}), do: nil
  defp caption(%{hide_label: true}), do: nil
  defp caption(%{label: label}), do: label

  defp bar_width(index), do: Enum.at(["w-full", "w-3/4", "w-1/2"], rem(index, 3))

  defp columns(assigns) do
    length(assigns.col) + count(assigns.selectable) + count(assigns.expanded != []) +
      count(assigns.action != [])
  end

  defp count(true), do: 1
  defp count(false), do: 0

  defp sort_state(%{key: key}, {key, :asc}), do: "ascending"
  defp sort_state(%{key: key}, {key, :desc}), do: "descending"
  defp sort_state(%{sortable: true}, _sort), do: "none"
  defp sort_state(_col, _sort), do: nil

  defp entries(%Phoenix.LiveView.LiveStream{} = stream, _row_id, _id, _group_by), do: stream

  defp entries(rows, row_id, id, group_by),
    do: rows |> Enum.map(&{"#{id}-row-#{row_id.(&1)}", &1}) |> grouped(group_by)

  defp grouped(entries, nil), do: entries

  defp grouped(entries, group_by) do
    entries
    |> Enum.chunk_by(fn {_dom_id, row} -> group_by.(row) end)
    |> Enum.flat_map(fn [{_dom_id, first} | _] = chunk ->
      [{:group, group_by.(first), Enum.map(chunk, &elem(&1, 1))} | chunk]
    end)
  end

  defp streaming?(%Phoenix.LiveView.LiveStream{}), do: true
  defp streaming?(_rows), do: false

  defp selected?(ticked, id), do: MapSet.member?(ticked, to_string(id))

  defp direction(%{key: key}, {key, dir}), do: dir
  defp direction(_col, _sort), do: :none

  defp sorted?(col, sort), do: direction(col, sort) != :none

  attr :dir, :atom, required: true
  attr :asc, :list, required: true
  attr :desc, :list, required: true
  attr :none, :list, required: true

  defp sort_icon(%{dir: :asc, asc: [_ | _]} = assigns), do: ~H"{render_slot(@asc)}"
  defp sort_icon(%{dir: :asc} = assigns), do: ~H"↑"
  defp sort_icon(%{dir: :desc, desc: [_ | _]} = assigns), do: ~H"{render_slot(@desc)}"
  defp sort_icon(%{dir: :desc} = assigns), do: ~H"↓"
  defp sort_icon(%{dir: :none, none: [_ | _]} = assigns), do: ~H"{render_slot(@none)}"
  defp sort_icon(assigns), do: ~H"↕"
end
