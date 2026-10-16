defmodule DevactionUI.AuthLayout do
  @moduledoc """
  The page around a sign-in screen: a framed panel with two columns. On the left the product (its mark and name,
  a headline and a few reasons to sign in); on the right whatever the screen needs, usually an `AuthCard`; along
  the bottom a copyright line and a few links. The columns wrap on a narrow screen, the product above the form.

  It draws no logo and says nothing itself: the mark is the `brand` slot, every word is an attribute or slot, so
  the same layout serves any product. Colours are tokens (`--auth-bg`, `--auth-frame`, `--auth-frame-line`), so
  it follows the light and the dark theme.

  The two columns are the page's `<main>`, whose `id` (`main_id`, `"main"` by default) is where a skip link
  of the host points. The footer links are a `<nav>` named by `nav_label`.

  The brand is the `brand` slot. `auth_brand/1` draws the canvas's pattern in it: a 34 px tile on the product's
  dark ground (the `--brand-tile` and `--brand-tile-line` tokens, the same `AuthCard` uses for its
  `icon_tone: :brand`) holding your symbol in its `mark` slot, and the name at 18 px semibold. The footer text
  and the icons of the reasons have their own tokens too (`--auth-foot`, `--auth-feature`), and the strip of
  `AuthCard` has `--auth-strip` and `--auth-strip-line`.
  """
  use Phoenix.Component

  attr :about_label, :string,
    required: true,
    doc: "names the product column for assistive technology"

  attr :headline, :string, required: true
  attr :copyright, :string, required: true
  attr :nav_label, :string, required: true, doc: "names the footer links for assistive technology"
  attr :main_id, :string, default: "main", doc: "the id of `<main>`, the target of a skip link"
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
        <main
          id={@main_id}
          class="flex flex-1 flex-wrap items-center justify-center gap-x-24 gap-y-16"
        >
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
                  class="grid size-9 flex-none place-items-center rounded-[10px] border border-line bg-(--auth-feature) text-ink-2"
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
        </main>
        <footer class="flex flex-wrap items-center justify-between gap-3 text-[13px] text-(--auth-foot)">
          <span>{@copyright}</span>
          <nav :if={@link != []} aria-label={@nav_label} class="flex gap-[18px]">
            <.link
              :for={link <- @link}
              href={link.href}
              class="text-(--auth-foot) underline hover:text-ink"
            >
              {render_slot(link)}
            </.link>
          </nav>
        </footer>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true, doc: "the product's name"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :mark, required: true, doc: "the symbol, drawn by the caller, about 32 px"

  @doc "The product's mark on its dark tile and its name, for the `brand` slot of `auth_layout/1`."
  @spec auth_brand(map()) :: Phoenix.LiveView.Rendered.t()
  def auth_brand(assigns) do
    ~H"""
    <span
      class={[
        "grid size-[34px] place-items-center rounded-[9px] border border-(--brand-tile-line) bg-(--brand-tile)",
        @class
      ]}
      aria-hidden="true"
      {@rest}
    >
      {render_slot(@mark)}
    </span>
    <span class="text-lg font-semibold tracking-[-0.01em] text-ink">{@name}</span>
    """
  end
end
