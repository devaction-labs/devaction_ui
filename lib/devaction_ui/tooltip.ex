defmodule DevactionUI.Tooltip do
  @moduledoc """
  A short hint on hover and on keyboard focus, drawn by CSS only. The trigger is the slot; `text` is what it
  says, tied to the trigger with `aria-describedby`. It is for a name or a short explanation, never for
  something the person must read to continue.

  It appears on the four sides, waits a moment before showing (so passing over a button does not flash), can
  show the shortcut of the action as a key cap and, with a `title`, is the rich variant: a heading and a
  paragraph in a wider box. Every button that is only an icon should have one.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :text, :string, required: true
  attr :placement, :atom, values: [:top, :bottom, :left, :right], default: :top
  attr :shortcut, :string, default: nil, doc: "the keys of the action, shown as a key cap: `⌘K`"
  attr :title, :string, default: nil, doc: "a heading: makes the rich variant"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  attr :rest, :global

  def tooltip(assigns) do
    ~H"""
    <span class={["group/tip relative inline-flex", @class]} aria-describedby={"#{@id}-tip"} {@rest}>
      {render_slot(@inner_block)}
      <span
        id={"#{@id}-tip"}
        role="tooltip"
        data-side={@placement}
        class={[
          "pointer-events-none absolute z-50 w-max rounded-lg bg-ink text-[13px] leading-snug text-on-primary opacity-0 shadow-lg transition-opacity delay-0",
          "group-hover/tip:opacity-100 group-hover/tip:delay-[400ms] group-focus-within/tip:opacity-100 group-focus-within/tip:delay-0 motion-reduce:transition-none",
          (@title && "flex max-w-72 flex-col gap-1 px-3.5 py-3") ||
            "inline-flex max-w-64 items-center gap-2 px-2.5 py-2",
          side_class(@placement)
        ]}
      >
        <strong :if={@title} class="font-semibold">{@title}</strong>
        <span>{@text}</span>
        <kbd
          :if={@shortcut}
          class="rounded bg-on-primary/20 px-1.5 font-mono text-[10px] text-on-primary"
        >
          {@shortcut}
        </kbd>
      </span>
    </span>
    """
  end

  defp side_class(:top), do: "bottom-full left-1/2 mb-2 -translate-x-1/2"
  defp side_class(:bottom), do: "top-full left-1/2 mt-2 -translate-x-1/2"
  defp side_class(:left), do: "right-full top-1/2 mr-2 -translate-y-1/2"
  defp side_class(:right), do: "left-full top-1/2 ml-2 -translate-y-1/2"
end
