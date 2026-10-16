defmodule DevactionUI.SortableList do
  @moduledoc """
  A list whose rows the person puts in order: drag a row by its handle (a mouse, a pen or a finger), press the up and down
  buttons of a row (off at the ends), or focus the handle and press Space to pick the row up, ↑ ↓ to move it
  (Home and End go to the ends), Space or Enter to drop it and Esc to put it back (`DevactionUI.SortableList`
  hook). A row has a handle, a mono `code`, a `label`, a `status` text at the right and the two buttons.

  The server owns the order: the rows are drawn in the order of the `row` slots, and when a move ends the hook sends
  `event` (`"reorder"`) to the LiveView, or to `target` inside a LiveComponent, with
  `%{"order" => [ids], "id" => moved, "from" => index, "to" => index}`; `order` has every id in the new order. The row
  moves in the page at once; the LiveView stores the order and draws the rows again in it. A drop that changes
  nothing sends nothing, and a change of the `row` slots from the server wins over what the page shows.

  The list is named for assistive technology (`label`), every handle is a button named by `handle_label` and the row, and
  described by `hint_label` (how to use the keyboard). Each step is said in a live region, under the list, in the
  caller's words: `picked_label`, `moved_label`, `dropped_label` and `cancelled_label`, in which `__ITEM__`,
  `__POS__` and `__TOTAL__` are replaced by the name of the row and its place. The library holds no language and no
  icons: the texts are attrs and the icons are slots (`handle_icon`, `up_icon`, `down_icon`, each with a glyph in
  place of an icon the caller does not give).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the list, for assistive technology"

  attr :event, :string,
    default: "reorder",
    doc: "the event sent when a move ends, with `order`, `id`, `from` and `to`"

  attr :handle_label, :string,
    required: true,
    doc: "the name of a handle, before the name of its row"

  attr :up_label, :string,
    required: true,
    doc: "the name of the up button, before the name of its row"

  attr :down_label, :string,
    required: true,
    doc: "the name of the down button, before the name of its row"

  attr :hint_label, :string,
    required: true,
    doc: "how to move a row with the keyboard, read after the name of a handle"

  attr :picked_label, :string,
    required: true,
    doc: "said when a row is picked up; takes `__ITEM__`, `__POS__`, `__TOTAL__`"

  attr :moved_label, :string,
    required: true,
    doc: "said when a row moves; takes `__ITEM__`, `__POS__`, `__TOTAL__`"

  attr :dropped_label, :string,
    required: true,
    doc: "said when a row is dropped; takes `__ITEM__`, `__POS__`, `__TOTAL__`"

  attr :cancelled_label, :string,
    required: true,
    doc: "said when a move is given up; takes `__ITEM__`, `__POS__`, `__TOTAL__`"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :class, :any, default: nil

  slot :row, required: true, doc: "a row of the list" do
    attr :id, :string, required: true, doc: "what the order is made of"

    attr :label, :string,
      required: true,
      doc: "the name of the row, read out and said when it moves"

    attr :code, :string, doc: "a short mono code before the label, such as `M3`"
    attr :status, :string, doc: "the text at the right, such as a date or a state"
  end

  slot :handle_icon, doc: "the grip of the handle"
  slot :up_icon, doc: "the arrow of the up button"
  slot :down_icon, doc: "the arrow of the down button"
  attr :rest, :global

  @spec list(map()) :: Phoenix.LiveView.Rendered.t()
  def list(assigns) do
    assigns = assign(assigns, :last, length(assigns.row) - 1)

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.SortableList"
      phx-target={@target}
      data-event={@event}
      data-picked-label={@picked_label}
      data-moved-label={@moved_label}
      data-dropped-label={@dropped_label}
      data-cancelled-label={@cancelled_label}
      class={["flex flex-col gap-2.5", @class]}
      {@rest}
    >
      <span id={"#{@id}-hint"} class="sr-only">{@hint_label}</span>
      <ul data-sortable-list aria-label={@label} class="m-0 flex list-none flex-col gap-1.5 p-0">
        <li
          :for={{row, index} <- Enum.with_index(@row)}
          id={"#{@id}-row-#{row.id}"}
          data-sortable-row
          data-id={row.id}
          data-label={row.label}
          phx-mounted={JS.ignore_attributes(["data-dragging"])}
          class="relative flex h-[50px] items-center gap-2.5 rounded-xl border border-line bg-card px-2.5 transition-[transform,box-shadow] data-[dragging]:z-10 data-[dragging]:scale-[1.01] data-[dragging]:border-ink data-[dragging]:shadow-pop motion-reduce:transition-none motion-reduce:data-[dragging]:scale-100"
        >
          <span
            data-handle
            role="button"
            tabindex="0"
            aria-label={"#{@handle_label} #{row.label}"}
            aria-describedby={"#{@id}-hint"}
            aria-pressed="false"
            phx-mounted={JS.ignore_attributes(["aria-pressed"])}
            class="grid size-6 shrink-0 cursor-grab touch-none place-items-center rounded-md text-muted-2 outline-none select-none hover:text-ink focus-visible:ring-4 focus-visible:ring-ink/10 active:cursor-grabbing"
          >
            {render_slot(@handle_icon) || "⠿"}
          </span>
          <span :if={Map.get(row, :code)} class="w-[26px] shrink-0 font-mono text-xs text-muted">
            {row.code}
          </span>
          <span class="min-w-0 flex-1 truncate text-sm font-medium">{row.label}</span>
          <span :if={Map.get(row, :status)} class="shrink-0 text-xs text-muted">
            {row.status}
          </span>
          <.step direction="up" label={"#{@up_label} #{row.label}"} off={index == 0}>
            {render_slot(@up_icon) || "↑"}
          </.step>
          <.step direction="down" label={"#{@down_label} #{row.label}"} off={index == @last}>
            {render_slot(@down_icon) || "↓"}
          </.step>
        </li>
      </ul>
      <div
        id={"#{@id}-live"}
        data-live
        phx-update="ignore"
        aria-live="polite"
        class="min-h-[18px] text-[13px] text-ink-2"
      >
      </div>
    </div>
    """
  end

  attr :direction, :string, required: true
  attr :label, :string, required: true
  attr :off, :boolean, required: true
  slot :inner_block, required: true

  defp step(assigns) do
    ~H"""
    <button
      type="button"
      data-move={@direction}
      aria-label={@label}
      disabled={@off}
      class="grid size-[26px] shrink-0 place-items-center rounded-[7px] border border-line bg-card text-xs text-ink outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:bg-card"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
