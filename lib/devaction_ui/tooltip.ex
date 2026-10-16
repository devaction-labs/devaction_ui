defmodule DevactionUI.Tooltip do
  @moduledoc """
  A short hint on hover and on keyboard focus, drawn by CSS and tied to its trigger by a small hook
  (`DevactionUI.Tooltip`). The trigger is the slot; `text` is what it says. The hook puts `aria-describedby`
  on the first focusable control inside the slot (the screen reader only reads the description of the focused
  element, so it cannot sit on the wrapper) and lets Esc dismiss the hint while the pointer or the focus is
  still there. It is for a name or a short explanation, never for something the person must read to continue:
  on a screen with no hover it does not appear.

  It appears on the four sides with an arrow towards the trigger, waits a moment before showing (so passing
  over a button does not flash), can show the shortcut of the action as a key cap (`DevactionUI.Kbd` in its
  inverse tone) and, with a `title`, is the rich variant: a heading and a paragraph in a wider box. Every
  button that is only an icon should have one.

  It follows WCAG 1.4.13: it is *dismissable* (Esc closes it, and so does a tap on a touch screen), *hoverable*
  (the pointer can cross the gap and rest on the hint without it closing; a bridge fills the gap) and
  *persistent* (it stays while the pointer or the focus is on the trigger or on the hint, until it is dismissed).
  The hook measures the hint when it is about to show and keeps it on the screen: with no room on the
  `placement` side it flips to the opposite side when that has more room, and it slides along the trigger,
  with the arrow still pointing at it, when it would cross the edge of the screen. It looks at the window
  only: an ancestor with `overflow: hidden` still clips it, so keep the trigger out of one.
  """
  use Phoenix.Component

  import DevactionUI.Kbd

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :text, :string, required: true
  attr :placement, :atom, values: [:top, :bottom, :left, :right], default: :top

  attr :shortcut, :string,
    default: nil,
    doc:
      "the keys of the action, shown as a key cap: `⌘K` (write `Ctrl` where the person is not on a Mac)"

  attr :title, :string, default: nil, doc: "a heading: makes the rich variant"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  attr :rest, :global

  @spec tooltip(map()) :: Phoenix.LiveView.Rendered.t()
  def tooltip(assigns) do
    ~H"""
    <span
      id={@id}
      phx-hook="DevactionUI.Tooltip"
      data-tip={"#{@id}-tip"}
      class={["group/tip relative inline-flex", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        id={"#{@id}-tip"}
        role="tooltip"
        data-side={@placement}
        data-placement={@placement}
        phx-mounted={JS.ignore_attributes(["data-side", "style"])}
        class={[
          "tip pointer-events-none absolute z-50 w-max bg-ink text-xs text-on-primary opacity-0 transition-opacity delay-0",
          "group-hover/tip:pointer-events-auto group-hover/tip:opacity-100 group-hover/tip:delay-[400ms] group-focus-within/tip:pointer-events-auto group-focus-within/tip:opacity-100 group-focus-within/tip:delay-0 motion-reduce:transition-none",
          "group-data-[dismissed]/tip:!pointer-events-none group-data-[dismissed]/tip:!opacity-0",
          (@title && "flex max-w-[280px] flex-col gap-1 rounded-xl px-3.5 py-3 shadow-tip-rich") ||
            "inline-flex max-w-64 items-center gap-2 rounded-lg px-[9px] py-1.5 leading-snug shadow-tip"
        ]}
      >
        <strong :if={@title} class="text-[13px] font-semibold">{@title}</strong>
        <span class={@title && "leading-normal text-on-primary/80"}>{@text}</span>
        <.kbd :if={@shortcut} tone={:inverse}>{@shortcut}</.kbd>
        <span aria-hidden="true" class="tip-arrow" />
      </span>
    </span>
    """
  end
end
