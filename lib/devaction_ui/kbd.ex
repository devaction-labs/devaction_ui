defmodule DevactionUI.Kbd do
  @moduledoc """
  A key cap: ⌘K, ESC, ↵. Mono 11px with a thicker bottom edge, as the canvas draws the keyboard hints.

  `tone` picks where it sits: `:default` is the cap on a light surface, `:inverse` is the small 10px cap
  inside a dark surface (the tooltip), with no border, and `:bare` is just the mono text, without border or
  background (the shortcut at the end of a menu row). `size: :md` is the larger cap of the command palette's
  Esc. The keys are the caller's text: `⌘` is a Mac key, so write `Ctrl` where the person is not on a Mac.
  """
  use Phoenix.Component

  attr :tone, :atom, values: [:default, :inverse, :bare], default: :default

  attr :size, :atom,
    values: [:sm, :md],
    default: :sm,
    doc: "`:md` only changes the `:default` cap"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @spec kbd(map()) :: Phoenix.LiveView.Rendered.t()
  def kbd(assigns) do
    ~H"""
    <kbd class={[tone_class(@tone, @size), @class]} {@rest}>
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  defp tone_class(:default, :sm),
    do: [cap(), "px-1.5 py-0.5"]

  defp tone_class(:default, :md),
    do: [cap(), "px-[7px] py-[3px]"]

  defp tone_class(:inverse, _size),
    do: "rounded px-[5px] py-px font-mono text-[10px] bg-kbd-inverse text-kbd-inverse-fg"

  defp tone_class(:bare, _size), do: "font-mono text-[11px] text-muted"

  defp cap,
    do: "rounded-md border border-b-2 border-line bg-card font-mono text-[11px] text-ink-2"
end
