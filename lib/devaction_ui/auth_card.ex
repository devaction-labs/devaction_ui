defmodule DevactionUI.AuthCard do
  @moduledoc """
  The card of a sign-in screen: a header with a soft grid and an amber glow behind an icon tile, a title and a
  line of text, then the form, and optionally a quieter strip at the bottom for the other way in ("No account?
  Create one"). One screen is one card, or a card and a note under it.

  The icon is the `icon` slot; `icon_tone: :brand` puts it on the product's dark tile (the `--brand-tile` and
  `--brand-tile-line` tokens), `:plain` on a card-coloured one, and `icon_class` tints it further (an envelope or
  a lock on an amber one). `heading` is the level of the title: `:h1` when the card is the page, `:h2` when
  something else already is. The text is `text`, or the `subtitle` slot when part of it is bold, such as an e-mail
  address.
  """
  use Phoenix.Component

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :heading, :atom, values: [:h1, :h2], default: :h1
  attr :icon_tone, :atom, values: [:plain, :brand], default: :plain
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
          <span
            :if={@icon != []}
            class={["auth-icon", icon_tone(@icon_tone), @icon_class]}
            aria-hidden="true"
          >
            {render_slot(@icon)}
          </span>
          <.heading level={@heading} title={@title} />
          <p :if={@text} class="m-0 max-w-[330px] text-[15px] leading-normal text-muted">{@text}</p>
          <p :if={@subtitle != []} class="m-0 max-w-[330px] text-[15px] leading-normal text-muted">
            {render_slot(@subtitle)}
          </p>
        </div>
        {render_slot(@inner_block)}
      </div>
      <div
        :if={@footer != []}
        class="relative border-t border-line bg-wrap px-7 py-[18px] text-center text-sm text-muted"
      >
        {render_slot(@footer)}
      </div>
    </section>
    """
  end

  attr :level, :atom, required: true
  attr :title, :string, required: true

  defp heading(%{level: :h1} = assigns), do: ~H"<h1 class={heading_class()}>{@title}</h1>"
  defp heading(%{level: :h2} = assigns), do: ~H"<h2 class={heading_class()}>{@title}</h2>"

  defp heading_class, do: "m-0 mt-1 text-[26px] font-semibold tracking-[-0.02em] text-ink"

  defp icon_tone(:plain), do: nil
  defp icon_tone(:brand), do: "border-(--brand-tile-line) bg-(--brand-tile)"
end
