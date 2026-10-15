defmodule DevactionUI.AuthLayout do
  @moduledoc """
  The page around a sign-in screen: a framed panel with two columns. On the left the product (its mark and name,
  a headline and a few reasons to sign in); on the right whatever the screen needs, usually an `AuthCard`; along
  the bottom a copyright line and a few links. The columns wrap on a narrow screen, the product above the form.

  It draws no logo and says nothing itself: the mark is the `brand` slot, every word is an attribute or slot, so
  the same layout serves any product. Colours are tokens, so it follows the light and the dark theme.
  """
  use Phoenix.Component

  attr :about_label, :string,
    required: true,
    doc: "names the product column for assistive technology"

  attr :headline, :string, required: true
  attr :copyright, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :brand, required: true, doc: "the product's mark and name"

  slot :feature, doc: "a reason to sign in; the slot body is its icon" do
    attr :title, :string, required: true
    attr :text, :string, required: true
  end

  slot :link, doc: "a link in the footer" do
    attr :href, :string, required: true
  end

  slot :inner_block, required: true, doc: "the right column: the form's card or cards"

  def auth_layout(assigns) do
    ~H"""
    <div class={["auth-page", @class]} {@rest}>
      <div class="auth-frame">
        <div class="flex flex-1 flex-wrap items-center justify-center gap-x-24 gap-y-16">
          <section
            aria-label={@about_label}
            class="flex max-w-[480px] flex-[1_1_380px] flex-col gap-8"
          >
            <div class="flex items-center gap-2.5">{render_slot(@brand)}</div>
            <p class="m-0 text-[26px] leading-[1.3] font-medium tracking-[-0.02em] text-ink">
              {@headline}
            </p>
            <ul :if={@feature != []} class="m-0 flex list-none flex-col gap-[22px] p-0">
              <li :for={feature <- @feature} class="flex gap-3.5">
                <span
                  class="grid size-9 flex-none place-items-center rounded-[10px] border border-line bg-wrap text-ink-2"
                  aria-hidden="true"
                >
                  {render_slot(feature)}
                </span>
                <span class="flex flex-col gap-1">
                  <span class="font-medium text-ink">{feature.title}</span>
                  <span class="text-sm leading-normal text-muted">{feature.text}</span>
                </span>
              </li>
            </ul>
          </section>
          <div class="flex min-w-0 flex-[0_1_420px] flex-col gap-5">
            {render_slot(@inner_block)}
          </div>
        </div>
        <footer class="flex flex-wrap items-center justify-between gap-3 text-[13px] text-muted">
          <span>{@copyright}</span>
          <nav :if={@link != []} class="flex gap-5">
            <.link :for={link <- @link} href={link.href} class="text-muted underline hover:text-ink">
              {render_slot(link)}
            </.link>
          </nav>
        </footer>
      </div>
    </div>
    """
  end
end
