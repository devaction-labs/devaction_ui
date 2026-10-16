defmodule DevactionUI.HoverCard do
  @moduledoc """
  A card of more about a name, a number or a link (a person with a few figures, a pull request with what blocks it) that
  opens when the pointer rests on its trigger for 400 ms or the keyboard focus reaches it, and closes when both have
  left (`DevactionUI.HoverCard` hook). The trigger is the slot, drawn with a dotted underline; the card is the
  `inner_block`. It adds information and never the only way to do something: whatever is in it must also be on the page the
  trigger leads to.

  It follows WCAG 1.4.13, like `DevactionUI.Tooltip`: it is *dismissable* (Esc closes it, and the Esc still reaches a dialog
  around it), *hoverable* (the card is part of what the pointer leaves, and closing waits `close_delay` ms, so the pointer
  can cross the gap and rest on the card) and *persistent* (it stays while the pointer or the focus is on the trigger or on
  the card). On a touch screen a tap on the trigger opens it, without following a link under the finger, and a tap
  anywhere else closes it. The card is kept inside the window, flipping to the other side and sliding along the trigger
  (`DevactionUI.Tooltip` takes the same measures from `placement.js`).

  The trigger gets `aria-describedby` pointing at the card; without a focusable control in the slot the trigger itself
  joins the Tab order. The card is a group named by `label`. Everything is a `span`, so the card may sit inside a paragraph: give the content `span`s with `block` or `flex`, never `div`s.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the name of the card, for assistive technology"
  attr :placement, :atom, values: [:top, :bottom], default: :bottom, doc: "the side it prefers"

  attr :open_delay, :integer,
    default: 400,
    doc: "milliseconds of pointer on the trigger before it opens"

  attr :close_delay, :integer,
    default: 150,
    doc: "milliseconds before it closes after the pointer and the focus left"

  attr :underline, :boolean, default: true, doc: "the dotted underline of the trigger"
  attr :class, :any, default: nil
  attr :trigger_class, :any, default: nil, doc: "more classes for the trigger"
  attr :card_class, :any, default: nil, doc: "more classes for the card, such as its width"
  slot :trigger, required: true, doc: "what the pointer rests on: a name, a number, a link"
  slot :inner_block, required: true, doc: "the content of the card"
  attr :rest, :global

  @spec card(map()) :: Phoenix.LiveView.Rendered.t()
  def card(assigns) do
    ~H"""
    <span
      id={@id}
      phx-hook="DevactionUI.HoverCard"
      data-open-delay={@open_delay}
      data-close-delay={@close_delay}
      class={["relative inline-block", @class]}
      {@rest}
    >
      <span
        data-trigger
        class={[
          "rounded-sm outline-none focus-visible:ring-4 focus-visible:ring-ink/10",
          @underline && "font-medium underline decoration-dotted underline-offset-4",
          @trigger_class
        ]}
      >
        {render_slot(@trigger)}
      </span>
      <span
        id={"#{@id}-card"}
        data-card
        data-state="closed"
        data-side={@placement}
        data-placement={@placement}
        role="group"
        aria-label={@label}
        phx-mounted={JS.ignore_attributes(["data-state", "data-side", "style"])}
        class={[
          "invisible absolute left-1/2 z-50 -translate-x-1/2 opacity-0 transition-opacity [margin-left:var(--card-shift,0px)] data-[state=open]:visible data-[state=open]:opacity-100 motion-reduce:transition-none",
          "data-[side=top]:bottom-full data-[side=top]:pb-2 data-[side=bottom]:top-full data-[side=bottom]:pt-2"
        ]}
      >
        <span class={[
          "block w-max max-w-[min(22rem,calc(100vw-1rem))] rounded-[14px] border border-line bg-card text-left text-sm font-normal text-ink no-underline shadow-menu",
          @card_class
        ]}>
          {render_slot(@inner_block)}
        </span>
      </span>
    </span>
    """
  end
end
