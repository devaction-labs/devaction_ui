defmodule DevactionUI.Popover do
  @moduledoc """
  A panel anchored to a button, with an arrow: the trigger opens and closes it, Esc and a click outside
  close it, focus goes into it when it opens and back to the trigger when it closes. It sits under (or over)
  the trigger inside the same box, so it is for a card, a form or a menu, not for something that has to
  escape a scrolling container.

  `placement` is `:bottom` or `:top`; the hook flips it when there is no room on the screen.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :placement, :atom, values: [:bottom, :top], default: :bottom
  attr :align, :atom, values: [:start, :end], default: :start
  attr :label, :string, required: true, doc: "the name of the panel, for assistive technology"
  attr :class, :any, default: nil
  attr :panel_class, :any, default: "w-80"

  slot :trigger,
    required: true,
    doc: "what is pressed; it gets the `button` role from the wrapper"

  slot :inner_block, required: true

  attr :rest, :global

  def popover(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Popover"
      data-placement={@placement}
      class={["relative inline-block", @class]}
      {@rest}
    >
      <span
        data-trigger
        aria-haspopup="dialog"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        class="inline-flex"
      >
        {render_slot(@trigger)}
      </span>
      <div
        id={"#{@id}-panel"}
        data-panel
        role="dialog"
        aria-label={@label}
        hidden
        phx-mounted={JS.ignore_attributes(["hidden", "data-side"])}
        tabindex="-1"
        class={[
          "absolute z-40 rounded-2xl border border-line bg-card p-4 shadow-[0_16px_40px_rgba(24,24,27,0.14)] outline-none",
          @align == :start && "left-0",
          @align == :end && "right-0",
          "data-[side=bottom]:top-full data-[side=bottom]:mt-2.5 data-[side=top]:bottom-full data-[side=top]:mb-2.5",
          @panel_class
        ]}
      >
        <span
          aria-hidden="true"
          class={[
            "absolute size-2.5 rotate-45 border-line bg-card",
            @align == :start && "left-7",
            @align == :end && "right-7",
            "data-[side=bottom]:-top-[6px] data-[side=bottom]:border-t data-[side=bottom]:border-l data-[side=top]:-bottom-[6px] data-[side=top]:border-r data-[side=top]:border-b"
          ]}
          data-arrow
        />
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
