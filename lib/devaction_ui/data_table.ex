defmodule DevactionUI.DataTable do
  @moduledoc """
  A table for lists that are worked on: sticky header, sortable columns (`aria-sort`, the server sorts and
  the table only draws the arrows), optional row selection with a tri-state header checkbox and a bulk
  bar that appears while something is selected, two densities and an empty state.

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
  from the caller, so the library carries no language of its own. There is no toolbar, density switch or
  footer: the page puts a search and a `DevactionUI.Pagination` around the table.
  """
  use Phoenix.Component

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
  attr :density, :atom, values: [:comfortable, :compact], default: :comfortable
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
  end

  slot :sort_asc_icon, doc: "the arrow of the column sorted ascending"
  slot :sort_desc_icon, doc: "the arrow of the column sorted descending"
  slot :sort_none_icon, doc: "the arrow of a sortable column that is not sorted"

  slot :bulk, doc: "the actions of the bulk bar"
  slot :empty, doc: "shown when there are no rows"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def data_table(assigns) do
    assigns =
      assign(assigns,
        entries: entries(assigns.rows, assigns.row_id, assigns.id),
        streaming: streaming?(assigns.rows),
        ticked: MapSet.new(assigns.selected, &to_string/1)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.DataTable"
      data-selected-label={@selected_label}
      class={["flex flex-col gap-2", @class]}
      {@rest}
    >
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

      <div class={["overflow-auto rounded-xl border border-line bg-card", @max_height]}>
        <table class="w-full border-collapse text-left text-sm">
          <caption class="sr-only">{@label}</caption>
          <thead>
            <tr>
              <th :if={@selectable} scope="col" class={[th(), "w-10"]}>
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
          <tbody id={"#{@id}-body"} phx-update={@streaming && "stream"}>
            <tr
              :for={{dom_id, row} <- @entries}
              id={dom_id}
              aria-selected={@selectable && to_string(selected?(@ticked, @row_id.(row)))}
              class="group/row hover:bg-wrap has-[input:checked]:bg-ink/[.03]"
            >
              <td :if={@selectable} class={[td(@density), "w-10"]}>
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
              <td :for={col <- @col} class={[td(@density), Map.get(col, :class)]}>
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
                {render_slot(@empty)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @doc false
  def default_id(%{id: id}), do: id

  defp th,
    do:
      "sticky top-0 z-10 border-b border-line bg-card px-3 py-2.5 font-mono text-[11px] font-medium uppercase tracking-[0.08em] text-muted"

  defp td(:comfortable), do: "border-b border-line-soft px-3 py-3 align-middle"
  defp td(:compact), do: "border-b border-line-soft px-3 py-1.5 align-middle"

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
