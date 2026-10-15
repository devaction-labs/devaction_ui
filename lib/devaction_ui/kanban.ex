defmodule DevactionUI.Kanban do
  @moduledoc """
  A board of columns with cards that move: drag a card to another column or to another place in its own,
  or focus it and press Alt + arrow keys (←→ between columns, ↑↓ within one). The hook moves the card in the
  page at once and tells the LiveView, which stays the source of truth: it receives the event with
  `%{"card" => id, "from" => column, "to" => column, "index" => position}` and re-renders.

  A column may have a `wip` limit: when it is full it turns red and takes no more cards from other columns.
  While a card is dragged the target shows a dashed "drop here" slot (`drop_label`). The caller gives the
  texts (`drop_label`, `full_label`, `moved_label` with `__COLUMN__`), so the library carries no language.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the board's name, for assistive technology"

  attr :event, :string,
    default: "move_card",
    doc: "the event sent to the LiveView when a card moves"

  attr :drop_label, :string, default: "Drop here"
  attr :full_label, :string, default: "Limit reached"
  attr :moved_label, :string, default: "Moved to __COLUMN__"
  attr :class, :any, default: nil

  slot :column, required: true do
    attr :id, :string, required: true
    attr :title, :string, required: true
    attr :wip, :integer, doc: "the most cards the column takes"
    attr :count, :integer, doc: "how many cards it has now (the hook keeps it after a move)"
  end

  attr :rest, :global

  def kanban(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Kanban"
      role="group"
      aria-label={@label}
      data-event={@event}
      data-moved-label={@moved_label}
      data-full-label={@full_label}
      class={["grid auto-cols-fr grid-flow-col gap-3 overflow-x-auto", @class]}
      {@rest}
    >
      <section
        :for={column <- @column}
        id={"#{@id}-col-#{column.id}"}
        data-column={column.id}
        data-title={column.title}
        data-wip={Map.get(column, :wip)}
        aria-label={column.title}
        class="flex min-w-56 flex-col gap-2.5 rounded-2xl bg-wrap p-3"
      >
        <header class="flex items-center justify-between gap-2 px-1 text-sm">
          <h3 class="m-0 text-sm font-semibold text-ink">{column.title}</h3>
          <span
            data-meter
            class="font-mono text-xs text-muted data-[full]:text-missing"
          >
            <span data-count>{Map.get(column, :count)}</span><span :if={Map.get(column, :wip)}>/{column.wip}</span>
          </span>
        </header>
        <div data-cards class="flex min-h-16 flex-col gap-2.5">
          {column.inner_block && render_slot(column)}
        </div>
      </section>
      <p
        id={"#{@id}-live"}
        data-live
        phx-update="ignore"
        class="sr-only"
        role="status"
        aria-live="polite"
      >
      </p>
      <template data-drop>
        <div
          data-drop-slot
          class="flex h-16 items-center justify-center rounded-xl border-[1.5px] border-dashed border-muted/60 text-sm text-muted"
        >
          {@drop_label}
        </div>
      </template>
    </div>
    """
  end

  attr :id, :string, required: true, doc: "the card's id; it is what the move event carries"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      id={@id}
      data-kanban-card
      data-card-id={@id}
      draggable="true"
      tabindex="0"
      class={[
        "flex cursor-grab flex-col gap-2.5 rounded-xl border border-line bg-card p-3.5 text-sm outline-none transition-shadow",
        "focus-visible:ring-4 focus-visible:ring-ink/10 data-[dragging]:rotate-2 data-[dragging]:cursor-grabbing data-[dragging]:shadow-[0_18px_40px_rgba(24,24,27,0.18)] motion-reduce:data-[dragging]:rotate-0",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
