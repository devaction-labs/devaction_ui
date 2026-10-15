defmodule DevactionUI.AuthCard do
  @moduledoc """
  The card of a sign-in screen: a header with a soft grid and an amber glow behind an icon tile, a title and a
  line of text, then the form, and optionally a quieter strip at the bottom for the other way in ("No account?
  Create one"). One screen is one card, or a card and a note under it.

  The icon is the `icon` slot; `icon_class` tints its tile (the product mark sits on a dark tile, an envelope or a
  lock on an amber one). The text is `text`, or the `subtitle` slot when part of it is bold, such as an e-mail
  address.
  """
  use Phoenix.Component

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :icon_class, :any, default: nil, doc: "classes for the icon's tile, over the default"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "the icon or the mark, drawn by the caller"
  slot :subtitle, doc: "rich text under the title, instead of `text`"
  slot :inner_block, required: true, doc: "the form or the content of the card"
  slot :footer, doc: "the strip under the form"

  def auth_card(assigns) do
    ~H"""
    <section class={["auth-card", @class]} {@rest}>
      <span class="auth-grid" aria-hidden="true"></span>
      <span class="auth-glow" aria-hidden="true"></span>
      <div class="relative flex flex-col gap-5 px-8 pt-9 pb-7">
        <div class="flex flex-col items-center gap-3 text-center">
          <span :if={@icon != []} class={["auth-icon", @icon_class]} aria-hidden="true">
            {render_slot(@icon)}
          </span>
          <h1 class="m-0 mt-1 text-[26px] font-semibold tracking-[-0.02em] text-ink">{@title}</h1>
          <p :if={@text} class="m-0 max-w-[330px] text-[15px] leading-normal text-muted">{@text}</p>
          <p :if={@subtitle != []} class="m-0 max-w-[330px] text-[15px] leading-normal text-muted">
            {render_slot(@subtitle)}
          </p>
        </div>
        {render_slot(@inner_block)}
      </div>
      <div
        :if={@footer != []}
        class="relative border-t border-line bg-wrap px-8 py-4 text-center text-sm text-muted"
      >
        {render_slot(@footer)}
      </div>
    </section>
    """
  end
end
