defmodule DevactionUI.Popover do
  @moduledoc """
  A panel anchored to a button, with an arrow: the trigger opens and closes it, Esc and a press outside
  (`pointerdown`, so touch works) close it, focus goes into it when it opens and back to the trigger when it
  closes. It is not modal and does not trap the focus: Tab past its last control closes it and the focus goes
  on to what follows the trigger, and Shift+Tab before its first control closes it and returns to the trigger.

  `placement` is `:bottom`, `:top`, `:right` or `:left`; the hook flips it to the opposite side when there is
  no room on the screen. The panel is 6 px from the trigger. `align` is `:start` or `:end`: the edge of the
  trigger the panel lines up with (its left or right edge for the vertical placements, its top or bottom for the
  horizontal ones). When the panel would cross the edge of the screen the hook shifts it, and the arrow stays on
  the trigger.

  By default the panel sits inside the same box as the trigger, so a scrolling ancestor clips it. With `portal`
  the hook moves the panel to the end of `document.body` while it is open and draws it with `position: fixed`
  from the rectangle of the trigger, repositioned on scroll and resize, over a modal (`z-80`). Events with
  `phx-click` inside a portal panel reach the main LiveView, not a nested one; the panel is put back in place
  before each update of the page, so what it shows stays current.

  The width is `w-80` unless `panel_class` has a width of its own. The `aria-haspopup`, `aria-controls` and
  `aria-expanded` of the trigger are put by the hook, so a page rendered with no JavaScript does not have them.
  The panel does not animate. Its shadow is the `shadow-pop` token, which has a version for the dark theme.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :placement, :atom, values: [:bottom, :top, :right, :left], default: :bottom
  attr :align, :atom, values: [:start, :end], default: :start

  attr :portal, :boolean,
    default: false,
    doc: "draw the panel at the level of `document.body`, so no scrolling ancestor clips it"

  attr :label, :string, required: true, doc: "the name of the panel, for assistive technology"
  attr :class, :any, default: nil

  attr :panel_class, :any,
    default: nil,
    doc: "extra classes of the panel; the width is `w-80` unless a width class is set here"

  slot :trigger,
    required: true,
    doc:
      "what is pressed; the hook puts `aria-haspopup`, `aria-expanded` and `aria-controls` on the button or link inside it (or makes the wrapper a button when there is none)"

  slot :inner_block, required: true

  attr :rest, :global

  def popover(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Popover"
      data-placement={@placement}
      data-align={@align}
      data-portal={@portal || nil}
      class={["relative inline-block", @class]}
      {@rest}
    >
      <span
        data-trigger
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
        phx-mounted={JS.ignore_attributes(["hidden", "data-side", "style"])}
        tabindex="-1"
        class={[
          "absolute z-40 [:where(&)]:w-80 rounded-2xl border border-line bg-card p-4 shadow-pop outline-none",
          @align == :start &&
            "data-[side=top]:left-0 data-[side=bottom]:left-0 data-[side=left]:top-0 data-[side=right]:top-0",
          @align == :end &&
            "data-[side=top]:right-0 data-[side=bottom]:right-0 data-[side=left]:bottom-0 data-[side=right]:bottom-0",
          "data-[side=bottom]:top-full data-[side=bottom]:mt-1.5 data-[side=top]:bottom-full data-[side=top]:mb-1.5",
          "data-[side=right]:left-full data-[side=right]:ml-1.5 data-[side=left]:right-full data-[side=left]:mr-1.5",
          @panel_class
        ]}
      >
        <span
          aria-hidden="true"
          class={[
            "absolute size-2.5 rotate-45 border-line bg-card",
            @align == :start &&
              "data-[side=top]:left-7 data-[side=bottom]:left-7 data-[side=left]:top-7 data-[side=right]:top-7",
            @align == :end &&
              "data-[side=top]:right-7 data-[side=bottom]:right-7 data-[side=left]:bottom-7 data-[side=right]:bottom-7",
            "data-[side=bottom]:-top-[6px] data-[side=bottom]:border-t data-[side=bottom]:border-l data-[side=top]:-bottom-[6px] data-[side=top]:border-r data-[side=top]:border-b",
            "data-[side=right]:-left-[6px] data-[side=right]:border-b data-[side=right]:border-l data-[side=left]:-right-[6px] data-[side=left]:border-t data-[side=left]:border-r"
          ]}
          phx-mounted={JS.ignore_attributes(["data-side", "style"])}
          data-arrow
        />
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
