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

  Texts (`select_all_label`, `select_row_label`, `selected_label` with `__COUNT__`, `clear_label`) come
  from the caller, so the library carries no language of its own.
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
  attr :max_height, :string, default: "max-h-[420px]"
  attr :select_all_label, :string, required: true
  attr :select_row_label, :string, required: true
  attr :selected_label, :string, required: true, doc: "with `__COUNT__`"
  attr :clear_label, :string, required: true
  attr :class, :any, default: nil

  slot :col, required: true do
    attr :label, :string, required: true
    attr :key, :string
    attr :sortable, :boolean
    attr :class, :string
  end

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
        streaming: streaming?(assigns.rows)
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
        class="flex flex-wrap items-center gap-3 rounded-xl bg-ink px-4 py-2.5 text-sm text-on-primary"
        role="status"
      >
        <span data-count class="font-medium"></span>
        <div class="flex flex-wrap items-center gap-2">{render_slot(@bulk)}</div>
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
                  class="size-4 accent-[var(--ink)]"
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
                  class="inline-flex items-center gap-1 font-mono text-[11px] font-medium uppercase tracking-[0.08em] outline-none hover:text-ink focus-visible:text-ink"
                >
                  {col.label}
                  <span aria-hidden="true">{arrow(col, @sort)}</span>
                </button>
                <span :if={!(Map.get(col, :sortable, false) && @on_sort)}>{col.label}</span>
              </th>
            </tr>
          </thead>
          <tbody id={"#{@id}-body"} phx-update={@streaming && "stream"}>
            <tr
              :for={{dom_id, row} <- @entries}
              id={dom_id}
              class="group/row hover:bg-wrap has-[input:checked]:bg-ink/[.04]"
            >
              <td :if={@selectable} class={[td(@density), "w-10"]}>
                <input
                  type="checkbox"
                  data-select-row
                  name={@name <> "[]"}
                  value={@row_id.(row)}
                  aria-label={@select_row_label}
                  class="size-4 accent-[var(--ink)]"
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

  defp arrow(%{key: key}, {key, :asc}), do: "↑"
  defp arrow(%{key: key}, {key, :desc}), do: "↓"
  defp arrow(_col, _sort), do: "↕"
end
