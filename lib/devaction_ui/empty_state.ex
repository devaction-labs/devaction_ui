defmodule DevactionUI.EmptyState do
  @moduledoc """
  What a list or a screen shows when there is nothing in it yet. Every empty one says what the area is, why it
  is empty and the one next step.

  `:dashed` (the default) is the card with a dashed border; `:page` is the whole-area one, with the squared
  grid behind its icon, a kicker, a title, a text and a main action with an optional second one; `:inline` is
  the small row inside a table, a list or a search with no result.

  `tone` colors what the variant shows: on `:inline`, `:neutral` is the dashed box of an empty search, `:ok` is
  the green row of a queue that is done and `:risk` the red row of a load that failed, with its `action`
  (\"Try again\") on the right; on `:page`, it tints the icon (`:warn` for something that needs attention).
  An inline one is `aria-live`, so a result that changes is read out.

  `heading_level` (2 to 6) is the level of the title of `:page` and `:dashed`; the inline one has no heading.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :variant, :atom, values: [:dashed, :page, :inline], default: :dashed

  attr :tone, :atom,
    values: [:neutral, :ok, :warn, :risk],
    default: :neutral,
    doc:
      "`:neutral`, `:ok` or `:risk` for `:inline`; `:neutral` or `:warn` for the icon of `:page`"

  attr :heading_level, :integer,
    values: [2, 3, 4, 5, 6],
    default: 2,
    doc: "the heading level of the title (`:page` and `:dashed`)"

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
      <span
        :if={@icon != []}
        class={["empty-icon", page_icon(@tone)]}
        aria-hidden="true"
      >
        {render_slot(@icon)}
      </span>
      <span :if={@kicker} class="relative font-mono text-[11px] tracking-[0.08em] text-muted">
        {@kicker}
      </span>
      <.heading
        level={@heading_level}
        class="relative m-0 text-xl font-semibold tracking-[-0.01em] text-ink"
      >
        {@title}
      </.heading>
      <p :if={@text} class="relative m-0 max-w-[400px] text-sm leading-[1.55] text-ink-2">{@text}</p>
      <span
        :if={@action != [] or @secondary != []}
        class="relative mt-1.5 flex flex-wrap justify-center gap-2"
      >
        {render_slot(@action)}{render_slot(@secondary)}
      </span>
    </div>
    """
  end

  def empty_state(%{variant: :inline, tone: tone} = assigns) when tone in [:ok, :risk] do
    ~H"""
    <div
      aria-live={live(@tone)}
      class={[
        "flex items-center gap-3 rounded-xl border p-[18px] text-left",
        Tone.surface(@tone),
        @class
      ]}
      {@rest}
    >
      <span :if={@icon != []} class={["size-5.5 shrink-0", Tone.text(@tone)]} aria-hidden="true">
        {render_slot(@icon)}
      </span>
      <span class="flex min-w-0 flex-1 flex-col">
        <span class={["text-sm font-medium", Tone.strong(@tone)]}>{@title}</span>
        <span :if={@text} class={["text-[13px]", Tone.text(@tone)]}>{@text}</span>
      </span>
      <div :if={@action != []} class="shrink-0">{render_slot(@action)}</div>
    </div>
    """
  end

  def empty_state(%{variant: :inline} = assigns) do
    ~H"""
    <div aria-live="polite" class={["empty-inline", @class]} {@rest}>
      <span :if={@icon != []} class="size-5.5 text-muted" aria-hidden="true">
        {render_slot(@icon)}
      </span>
      <span class="text-sm font-medium text-ink">{@title}</span>
      <span :if={@text} class="text-[13px] text-muted">{@text}</span>
      <div :if={@action != []} class="mt-1.5">{render_slot(@action)}</div>
    </div>
    """
  end

  def empty_state(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col items-center gap-2 rounded-[14px] border border-dashed border-line-dashed px-[18px] py-[22px] text-center",
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
      <.heading level={@heading_level} class="m-0 font-semibold tracking-[-0.01em] text-ink">
        {@title}
      </.heading>
      <p :if={@text} class="m-0 max-w-[400px] text-[13px] text-muted">{@text}</p>
      <div :if={@action != []} class="mt-1.5">{render_slot(@action)}</div>
    </div>
    """
  end

  attr :level, :integer, required: true
  attr :class, :string, required: true
  slot :inner_block, required: true

  defp heading(assigns) do
    ~H"""
    <.dynamic_tag tag_name={tag(@level)} class={@class}>{render_slot(@inner_block)}</.dynamic_tag>
    """
  end

  defp tag(2), do: "h2"
  defp tag(3), do: "h3"
  defp tag(4), do: "h4"
  defp tag(5), do: "h5"
  defp tag(6), do: "h6"

  defp live(:risk), do: "assertive"
  defp live(_tone), do: "polite"

  defp page_icon(:neutral), do: nil
  defp page_icon(tone), do: [Tone.surface(tone), Tone.text(tone)]
end
