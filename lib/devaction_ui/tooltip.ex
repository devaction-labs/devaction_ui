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
  button that is only an icon should have one. The box is placed by CSS next to the trigger and is not moved
  away from the edge of the screen or from an ancestor with `overflow`: pick the `placement` that has room.
  The hint itself ignores the pointer, so it never hides what is under it.
  """
  use Phoenix.Component

  import DevactionUI.Kbd

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
        class={[
          "pointer-events-none absolute z-50 w-max bg-ink text-xs text-on-primary opacity-0 transition-opacity delay-0",
          "group-hover/tip:opacity-100 group-hover/tip:delay-[400ms] group-focus-within/tip:opacity-100 group-focus-within/tip:delay-0 motion-reduce:transition-none",
          "group-data-[dismissed]/tip:!opacity-0",
          (@title && "flex max-w-[280px] flex-col gap-1 rounded-xl px-3.5 py-3 shadow-tip-rich") ||
            "inline-flex max-w-64 items-center gap-2 rounded-lg px-[9px] py-1.5 leading-snug shadow-tip",
          side_class(@placement)
        ]}
      >
        <strong :if={@title} class="text-[13px] font-semibold">{@title}</strong>
        <span class={@title && "leading-normal text-on-primary/80"}>{@text}</span>
        <.kbd :if={@shortcut} tone={:inverse}>{@shortcut}</.kbd>
        <span
          aria-hidden="true"
          class={["absolute size-0 border-[5px] border-transparent", arrow_class(@placement)]}
        />
      </span>
    </span>
    """
  end

  defp side_class(:top), do: "bottom-full left-1/2 mb-2 -translate-x-1/2"
  defp side_class(:bottom), do: "top-full left-1/2 mt-2 -translate-x-1/2"
  defp side_class(:left), do: "right-full top-1/2 mr-1.5 -translate-y-1/2"
  defp side_class(:right), do: "left-full top-1/2 ml-1.5 -translate-y-1/2"

  defp arrow_class(:top), do: "top-full left-1/2 -ml-[5px] border-t-ink"
  defp arrow_class(:bottom), do: "bottom-full left-1/2 -ml-[5px] border-b-ink"
  defp arrow_class(:left), do: "left-full top-1/2 -mt-[5px] border-l-ink"
  defp arrow_class(:right), do: "right-full top-1/2 -mt-[5px] border-r-ink"
end
