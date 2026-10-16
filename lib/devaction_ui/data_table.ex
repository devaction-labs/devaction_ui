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

    attr :sticky, :atom,
      values: [:start, :end],
      doc:
        "pins the column to the start (the first column) or the end (the actions) while the table scrolls sideways"
  end

  slot :sort_asc_icon, doc: "the arrow of the column sorted ascending"
  slot :sort_desc_icon, doc: "the arrow of the column sorted descending"
  slot :sort_none_icon, doc: "the arrow of a sortable column that is not sorted"

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

  def data_table(assigns) do
    assigns =
      assign(assigns,
        entries: entries(assigns.rows, assigns.row_id, assigns.id),
        streaming: streaming?(assigns.rows),
        ticked: MapSet.new(assigns.selected, &to_string/1),
        pinned: Enum.any?(assigns.col, &(Map.get(&1, :sticky) != nil)),
        pin_select: Enum.any?(assigns.col, &(Map.get(&1, :sticky) == :start))
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DataTable"
      data-selected-label={@selected_label}
      data-density={@density}
      class={["group/dt flex flex-col gap-2", @class]}
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
        <div class="flex flex-wrap items-center gap-2 [&>*]:inline-flex [&>*]:h-8 [&>*]:items-center [&>*]:rounded-lg [&>*]:bg-on-primary/15 [&>*]:px-3 [&>*]:text-[13px] [&>*]:outline-none hover:[&>*]:bg-on-primary/25 focus-visible:[&>*]:ring-2 focus-visible:[&>*]:ring-white/40">
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
        class={["overflow-auto rounded-xl border border-line bg-card", @max_height]}
        data-pinned={@pinned && ""}
        phx-hook={@pinned && "DevactionUI.ScrollArea"}
        phx-mounted={@pinned && JS.ignore_attributes(edge_attributes())}
      >
        <table class="w-full border-collapse text-left text-sm" aria-busy={@loading && "true"}>
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
              <th
                :for={col <- @col}
                scope="col"
                data-sticky={Map.get(col, :sticky)}
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
            </tr>
          </thead>
          <tbody
            id={"#{@id}-body"}
            phx-update={@streaming && "stream"}
            hidden={@loading or @error != nil}
          >
            <tr
              :for={{dom_id, row} <- @entries}
              id={dom_id}
              aria-selected={@selectable && to_string(selected?(@ticked, @row_id.(row)))}
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
                  value={@row_id.(row)}
                  checked={selected?(@ticked, @row_id.(row))}
                  aria-label={@select_row_label}
                  class="checkbox"
                />
              </td>
              <td
                :for={col <- @col}
                class={[td(), Map.get(col, :class)]}
                data-sticky={Map.get(col, :sticky)}
              >
                {render_slot(col, row)}
              </td>
            </tr>
            <tr
              :if={@streaming or @entries == []}
              id={"#{@id}-empty"}
              class={@streaming && "hidden only:table-row"}
            >
              <td
                colspan={columns(@col, @selectable)}
                class="px-4 py-8 text-center text-muted"
              >
                {(@empty != [] && render_slot(@empty)) || @empty_text}
              </td>
            </tr>
          </tbody>
          <tbody :if={@loading} aria-hidden="true">
            <tr :for={row <- 1..max(@loading_rows, 1)//1}>
              <td :if={@selectable} class={[td(), "w-10"]}>
                <.skeleton class="size-5 rounded-md" />
              </td>
              <td :for={{_col, at} <- Enum.with_index(@col)} class={td()}>
                <.skeleton class={bar_width(row + at)} />
              </td>
            </tr>
          </tbody>
          <tbody :if={@error && !@loading}>
            <tr>
              <td colspan={columns(@col, @selectable)} class="px-4 py-8 text-center">
                <div role="alert" class="flex flex-col items-center gap-3">
                  <span class="text-missing">{@error}</span>
                  {render_slot(@error_action)}
                </div>
              </td>
            </tr>
          </tbody>
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

  defp th,
    do:
      "sticky top-0 z-10 border-b border-line bg-card px-3 py-2.5 font-mono text-[11px] font-medium uppercase tracking-[0.08em] text-muted"

  defp td,
    do: "border-b border-line-soft px-3 py-3 align-middle group-data-[density=compact]/dt:py-1.5"

  defp bar_width(index), do: Enum.at(["w-full", "w-3/4", "w-1/2"], rem(index, 3))

  defp columns(cols, true), do: length(cols) + 1
  defp columns(cols, false), do: length(cols)

  defp sort_state(%{key: key}, {key, :asc}), do: "ascending"
  defp sort_state(%{key: key}, {key, :desc}), do: "descending"
  defp sort_state(%{sortable: true}, _sort), do: "none"
  defp sort_state(_col, _sort), do: nil

  defp entries(%Phoenix.LiveView.LiveStream{} = stream, _row_id, _id), do: stream
  defp entries(rows, row_id, id), do: Enum.map(rows, &{"#{id}-row-#{row_id.(&1)}", &1})

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
