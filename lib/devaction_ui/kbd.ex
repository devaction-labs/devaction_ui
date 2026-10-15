defmodule DevactionUI.Kbd do
  @moduledoc "A key cap: ⌘K, ESC, ↵. Mono 11px with a thicker bottom edge, as the canvas draws the keyboard hints."
  use Phoenix.Component

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kbd(assigns) do
    ~H"""
    <kbd
      class={[
        "rounded-md border border-b-2 border-line-strong bg-card px-1.5 py-0.5 font-mono text-[11px] text-ink-2",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end
end
