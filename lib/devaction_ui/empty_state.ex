defmodule DevactionUI.EmptyState do
  @moduledoc """
  What a list or a screen shows when there is nothing in it yet. Every empty one says what the area is, why it
  is empty and the one next step.

  `:dashed` (the default) is the card with a dashed border; `:page` is the whole-area one, with the squared
  grid behind its icon, a kicker, a title, a text and a main action with an optional second one; `:inline` is
  the small row inside a table, a list or a search with no result (and, with an action, the failure with
  \"Try again\").
  """
  use Phoenix.Component

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :variant, :atom, values: [:dashed, :page, :inline], default: :dashed
  attr :kicker, :string, default: nil, doc: "a small mono line over the title (`:page`)"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "the icon, drawn by the caller"
  slot :action, doc: "the button or link that fixes the emptiness"
  slot :secondary, doc: "a second, quieter way out (`:page`)"

  def empty_state(%{variant: :page} = assigns) do
    ~H"""
    <div class={["empty", @class]} {@rest}>
      <span class="empty-grid" aria-hidden="true" />
      <span :if={@icon != []} class="empty-icon" aria-hidden="true">{render_slot(@icon)}</span>
      <span :if={@kicker} class="relative font-mono text-[11px] tracking-[0.08em] text-muted">
        {@kicker}
      </span>
      <h2 class="relative m-0 text-xl font-semibold tracking-[-0.02em] text-ink">{@title}</h2>
      <p :if={@text} class="relative m-0 max-w-[420px] text-sm leading-normal text-ink-2">{@text}</p>
      <span
        :if={@action != [] or @secondary != []}
        class="relative mt-2 flex flex-wrap justify-center gap-2.5"
      >
        {render_slot(@action)}{render_slot(@secondary)}
      </span>
    </div>
    """
  end

  def empty_state(%{variant: :inline} = assigns) do
    ~H"""
    <div class={["empty-inline", @class]} {@rest}>
      <span :if={@icon != []} class="size-5 text-muted" aria-hidden="true">{render_slot(@icon)}</span>
      <span class="font-medium text-ink">{@title}</span>
      <span :if={@text} class="text-[13px] text-muted">{@text}</span>
      <div :if={@action != []} class="mt-1.5">{render_slot(@action)}</div>
    </div>
    """
  end

  def empty_state(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col items-center gap-2 rounded-[14px] border border-dashed border-line-strong px-[18px] py-[22px] text-center",
        @class
      ]}
      {@rest}
    >
      <span
        :if={@icon != []}
        class="flex size-10 items-center justify-center rounded-xl bg-wrap text-ink-2"
        aria-hidden="true"
      >
        {render_slot(@icon)}
      </span>
      <p class="m-0 font-semibold text-ink">{@title}</p>
      <p :if={@text} class="m-0 text-[13px] text-muted">{@text}</p>
      <div :if={@action != []} class="mt-1">{render_slot(@action)}</div>
    </div>
    """
  end
end
