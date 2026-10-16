defmodule DevactionUI.Email do
  @moduledoc """
  The frame and the text of an e-mail: the document with its `<head>`, the 600 px card with the brand above and the
  footer below, the heading, the paragraph, the button and the copy-and-paste link.

  An e-mail client has no Tailwind, no CSS variables and no flexbox: everything here is a table with inline styles,
  and the hex values are the canvas's own, kept in one place (a private style module). The only stylesheet is the
  `<style>` of `document/1`: the 600 px column, the narrow padding under 620 px and the dark mode, which the client
  turns on with `prefers-color-scheme` and which restyles the elements that carry an `em-*` class (`em-body`,
  `em-card`, `em-ink`, `em-muted`, `em-soft`, `em-line`, `em-panel`, `em-btn-primary`, `em-btn-secondary`).

  Every text is yours: the components draw no words of their own, so one e-mail can be written in any language.
  The sibling modules draw the rest: `DevactionUI.EmailTag`, `DevactionUI.EmailCallout` and `DevactionUI.EmailTable`.

  `document/1` wraps `layout/1`, and `to_html/1` turns the result into the string a mailer sends:

      <.document lang="en" title="Sign in">
        <.layout preheader="..." brand_name="Acme" brand_href="https://acme.test" logo_src="https://acme.test/logo.png" signature="Acme Inc.">
          <.heading>Sign in</.heading>
        </.layout>
      </.document>
  """

  use Phoenix.Component

  alias DevactionUI.Email.Style

  attr :lang, :string, required: true, doc: "the language of the e-mail, as in `en` or `pt-BR`"
  attr :title, :string, required: true, doc: "the `<title>`, usually the subject"

  attr :dark_scope, :string,
    default: nil,
    doc:
      "a CSS selector (`[data-theme=dark]`) that turns the dark rules on instead of the `prefers-color-scheme` query; for previews"

  attr :rest, :global, doc: "goes on the `<body>`"
  slot :inner_block, required: true

  @doc """
  The whole HTML document of an e-mail: doctype, `<head>` with the viewport and `color-scheme` metas and the one
  `<style>` the e-mail needs, and a `<body>` with the page background.

  ## Example

      <.document lang="en" title="Your link">
        <.layout ...>...</.layout>
      </.document>
  """
  @spec document(map()) :: Phoenix.LiveView.Rendered.t()
  def document(assigns) do
    ~H"""
    <!doctype html>
    <html lang={@lang} xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="x-apple-disable-message-reformatting" />
        <meta name="color-scheme" content="light dark" />
        <meta name="supported-color-schemes" content="light dark" />
        <title>{@title}</title>
        <.styles dark_scope={@dark_scope} />
      </head>
      <body
        class="em-body"
        style={"margin: 0; padding: 0; background: #{Style.color(:page)}"}
        {@rest}
      >
        {render_slot(@inner_block)}
      </body>
    </html>
    """
  end

  attr :dark_scope, :string,
    default: nil,
    doc: "a CSS selector that turns the dark rules on instead of the `prefers-color-scheme` query"

  attr :rest, :global, doc: "goes on the `<style>`"

  @doc """
  The `<style>` of an e-mail: the 600 px column, the narrow padding and the dark rules. `document/1` includes it;
  a preview inside another page can place it by itself, with a `dark_scope`.

  ## Example

      <.styles />
  """
  @spec styles(map()) :: Phoenix.LiveView.Rendered.t()
  def styles(assigns) do
    assigns =
      assign(
        assigns,
        :element,
        Phoenix.HTML.raw(
          "<style#{attributes(assigns.rest)}>#{Style.css(assigns.dark_scope)}</style>"
        )
      )

    ~H"""
    {@element}
    """
  end

  defp attributes(rest),
    do: rest |> Phoenix.HTML.attributes_escape() |> Phoenix.HTML.safe_to_string()

  @doc """
  Renders a `~H` result (or the output of a function component) to the HTML string a mailer sends.

  ## Example

      html = DevactionUI.Email.to_html(~H"<.heading>Hello</.heading>")
  """
  @spec to_html(Phoenix.LiveView.Rendered.t()) :: String.t()
  def to_html(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  attr :preheader, :string,
    required: true,
    doc: "the line a mail list shows after the subject; hidden in the body"

  attr :brand_name, :string, required: true, doc: "the name beside the logo"
  attr :brand_href, :string, required: true, doc: "where the logo and the name lead"
  attr :logo_src, :string, required: true, doc: "an absolute URL of the logo, a square image"
  attr :logo_size, :integer, default: 36, doc: "the logo's side in px"

  attr :signature, :string,
    required: true,
    doc: "the last footer line: the company and where it is"

  attr :rest, :global
  slot :inner_block, required: true, doc: "the content of the card"

  slot :footer,
    doc:
      "a paragraph of the footer above the signature; give one per line (why the e-mail came, links)"

  @doc """
  The page of an e-mail: the hidden preheader, the brand, the white card and the footer, in a 600 px column.

  Each `footer` slot is one paragraph; put a `footer_link/1` in it for preferences or unsubscribe.

  ## Example

      <.layout
        preheader="Click to sign in."
        brand_name="Acme"
        brand_href="https://acme.test"
        logo_src="https://acme.test/logo.png"
        signature="Acme Inc. · Springfield"
      >
        <.heading>Sign in</.heading>
        <:footer>You got this because you have an account.</:footer>
      </.layout>
  """
  @spec layout(map()) :: Phoenix.LiveView.Rendered.t()
  def layout(assigns) do
    ~H"""
    <div style="display: none; max-height: 0; overflow: hidden; opacity: 0; mso-hide: all">
      {@preheader}&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;
    </div>
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      class="em-body"
      style={"width: 100%; border-collapse: separate; border-spacing: 0; background: #{Style.color(:page)}"}
      {@rest}
    >
      <tbody>
        <tr>
          <td align="center" class="em-outer" style="padding: 40px 16px">
            <table
              role="presentation"
              border="0"
              cellpadding="0"
              cellspacing="0"
              width="600"
              style="width: 100%; max-width: 600px; border-collapse: separate; border-spacing: 0"
            >
              <tbody>
                <tr>
                  <td style="padding: 0 4px 20px">
                    <a href={@brand_href} style="text-decoration: none">
                      <table
                        role="presentation"
                        border="0"
                        cellpadding="0"
                        cellspacing="0"
                        style="border-collapse: separate; border-spacing: 0"
                      >
                        <tbody>
                          <tr>
                            <td style="vertical-align: middle; padding-right: 10px">
                              <img
                                src={@logo_src}
                                width={@logo_size}
                                height={@logo_size}
                                alt={@brand_name}
                                style="display: block; border: 0; border-radius: 9px"
                              />
                            </td>
                            <td
                              class="em-ink"
                              style={"vertical-align: middle; font-family: #{Style.sans()}; font-size: 17px; font-weight: 600; letter-spacing: -0.01em; color: #{Style.color(:ink)}"}
                            >
                              {@brand_name}
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </a>
                  </td>
                </tr>
                <tr>
                  <td
                    class="em-card em-pad"
                    style={"padding: 40px; border-radius: 16px; border: 1px solid #{Style.color(:line)}; background: #{Style.color(:card)}"}
                  >
                    {render_slot(@inner_block)}
                  </td>
                </tr>
                <tr>
                  <td style={"padding: 24px 8px 0; font-family: #{Style.sans()}; font-size: 12px; line-height: 1.6; color: #{Style.color(:soft)}"}>
                    <p :for={footer <- @footer} class="em-soft" style="margin: 0 0 8px">
                      {render_slot(footer)}
                    </p>
                    <p class="em-soft" style="margin: 0">{@signature}</p>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :href, :string, required: true
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  An underlined link for the footer paragraph: preferences, unsubscribe.

  ## Example

      <:footer>
        <.footer_link href="https://acme.test/prefs">Preferences</.footer_link>
      </:footer>
  """
  @spec footer_link(map()) :: Phoenix.LiveView.Rendered.t()
  def footer_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="em-soft"
      style={"color: #{Style.color(:muted)}; text-decoration: underline"}
      {@rest}
    >{render_slot(@inner_block)}</a>
    """
  end

  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  The title of the e-mail: 26 px, 600 weight, in the ink color.

  ## Example

      <.heading>Sign in to Acme</.heading>
  """
  @spec heading(map()) :: Phoenix.LiveView.Rendered.t()
  def heading(assigns) do
    ~H"""
    <h1
      class="em-ink"
      style={"margin: 0 0 16px; font-family: #{Style.sans()}; font-size: 26px; line-height: 1.25; font-weight: 600; letter-spacing: -0.02em; color: #{Style.color(:ink)}"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h1>
    """
  end

  attr :size, :atom,
    values: [:body, :compact, :small],
    default: :body,
    doc: "`:body` 16 px, `:compact` 15 px, `:small` 13 px in the soft color for the fine print"

  attr :lead, :boolean, default: false, doc: "the ink color, for the greeting line"
  attr :flush, :boolean, default: false, doc: "no margin below, for the last paragraph"
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A paragraph of the e-mail.

  ## Example

      <.paragraph>Click the button. The link works <.emphasis>once</.emphasis>.</.paragraph>
      <.paragraph size={:small} flush>If it was not you, ignore this e-mail.</.paragraph>
  """
  @spec paragraph(map()) :: Phoenix.LiveView.Rendered.t()
  def paragraph(assigns) do
    {color, class} = tone(assigns.size, assigns.lead)

    assigns =
      assigns
      |> assign(:color, color)
      |> assign(:class, class)
      |> assign(:margin, margin(assigns.flush))

    ~H"""
    <p
      class={@class}
      style={"margin: #{@margin}; #{Style.text(@size, @color)}"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp tone(_size, true), do: {:ink, "em-ink"}
  defp tone(:small, false), do: {:soft, "em-soft"}
  defp tone(_size, false), do: {:muted, "em-muted"}

  defp margin(true), do: "0"
  defp margin(false), do: "0 0 16px"

  attr :surface, :atom,
    values: [:card, :tint],
    default: :card,
    doc:
      "`:tint` inside a callout, whose light background stays light in dark mode and so must keep the dark ink"

  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A strong run of text inside a paragraph, in the ink color. On the card it turns light in dark mode with the rest
  of the ink; inside a tinted block, say `surface={:tint}` so it stays dark.

  ## Example

      <.paragraph>The link works for <.emphasis>15 minutes</.emphasis>.</.paragraph>
  """
  @spec emphasis(map()) :: Phoenix.LiveView.Rendered.t()
  def emphasis(assigns) do
    ~H"""
    <strong
      {emphasis_attrs(@surface)}
      style={"color: #{Style.color(:ink)}; font-weight: 600"}
      {@rest}
    >{render_slot(@inner_block)}</strong>
    """
  end

  defp emphasis_attrs(:card), do: [class: "em-ink"]
  defp emphasis_attrs(:tint), do: []

  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  The small mono caption above a block (a list, a table): 11 px, spaced, in the soft color. Write it in capitals.

  ## Example

      <.caption>WHAT TO LOOK AT</.caption>
  """
  @spec caption(map()) :: Phoenix.LiveView.Rendered.t()
  def caption(assigns) do
    ~H"""
    <p
      class="em-soft"
      style={"margin: 0 0 8px; font-family: #{Style.mono()}; font-size: 11px; line-height: normal; letter-spacing: 0.08em; color: #{Style.color(:soft)}"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :href, :string, required: true
  attr :variant, :atom, values: [:primary, :secondary], default: :primary
  attr :rest, :global, doc: "goes on the table that holds the button"
  slot :inner_block, required: true

  @doc """
  The button of the e-mail: a table cell with a link in it, 12 px radius, which every client draws the same.

  `:primary` is the ink button (it turns light in dark mode), `:secondary` the outlined one.

  ## Example

      <.button href={@url}>Sign in</.button>
      <.button href={@reset_url} variant={:secondary}>Reset password</.button>
  """
  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  def button(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      style="border-collapse: separate; margin: 8px 0 24px"
      {@rest}
    >
      <tbody>
        <tr>
          <.action href={@href} variant={@variant} compact={false}>
            {render_slot(@inner_block)}
          </.action>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :button, required: true, doc: "a button of the row" do
    attr :href, :string, required: true
    attr :variant, :atom, values: [:primary, :secondary]
  end

  attr :rest, :global

  @doc """
  Two or three buttons side by side, each a little narrower than a single `button/1`.

  ## Example

      <.button_row>
        <:button href={@draft_url}>Draft the renewal</:button>
        <:button href={@url} variant={:secondary}>Open contract</:button>
      </.button_row>
  """
  @spec button_row(map()) :: Phoenix.LiveView.Rendered.t()
  def button_row(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      style="border-collapse: collapse; margin: 8px 0 24px"
      {@rest}
    >
      <tbody>
        <tr>
          <td :for={button <- @button} style="padding-right: 10px">
            <table
              role="presentation"
              border="0"
              cellpadding="0"
              cellspacing="0"
              style="border-collapse: separate"
            >
              <tbody>
                <tr>
                  <.action
                    href={button.href}
                    variant={Map.get(button, :variant, :primary)}
                    compact
                  >
                    {render_slot(button)}
                  </.action>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :href, :string, required: true
  attr :variant, :atom, required: true
  attr :compact, :boolean, required: true
  slot :inner_block, required: true

  defp action(assigns) do
    ~H"""
    <td class={action_class(@variant)} style={action_cell(@variant)}>
      <a
        href={@href}
        target="_blank"
        style={"display: inline-block; padding: #{action_padding(@compact)}; font-family: #{Style.sans()}; font-size: 15px; font-weight: 600; line-height: 1; color: #{action_ink(@variant)}; text-decoration: none#{action_radius(@compact)}"}
      >{render_slot(@inner_block)}</a>
    </td>
    """
  end

  defp action_class(:primary), do: "em-btn-primary"
  defp action_class(:secondary), do: "em-btn-secondary"

  defp action_cell(:primary),
    do:
      "border-radius: 12px; background: #{Style.color(:ink)}; border: 1px solid #{Style.color(:ink)}"

  defp action_cell(:secondary),
    do:
      "border-radius: 12px; background: #{Style.color(:card)}; border: 1px solid #{Style.color(:outline)}"

  defp action_ink(:primary), do: Style.color(:on_ink)
  defp action_ink(:secondary), do: Style.color(:ink)

  defp action_padding(true), do: "14px 20px"
  defp action_padding(false), do: "14px 24px"

  defp action_radius(true), do: ""
  defp action_radius(false), do: "; border-radius: 12px"

  attr :href, :string, required: true, doc: "the address, shown as text and linked"
  attr :rest, :global
  slot :inner_block, required: true, doc: "the line above the address"

  @doc """
  The address to copy when the button does not work: a line of text and the URL in mono, breaking anywhere.

  ## Example

      <.link_fallback href={@url}>If the button does not work, paste this address in your browser:</.link_fallback>
  """
  @spec link_fallback(map()) :: Phoenix.LiveView.Rendered.t()
  def link_fallback(assigns) do
    ~H"""
    <p
      class="em-soft"
      style={"margin: 0 0 6px; font-family: #{Style.sans()}; font-size: 13px; line-height: normal; color: #{Style.color(:soft)}"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    <p style={"margin: 0 0 24px; font-family: #{Style.mono()}; font-size: 12px; line-height: 1.5; word-break: break-all"}>
      <a href={@href} class="em-muted" style={"color: #{Style.color(:muted)}"}>{@href}</a>
    </p>
    """
  end

  attr :rest, :global

  @doc """
  A thin rule between the body and the fine print.

  ## Example

      <.divider />
  """
  @spec divider(map()) :: Phoenix.LiveView.Rendered.t()
  def divider(assigns) do
    ~H"""
    <div
      class="em-line"
      style={"height: 1px; background: #{Style.color(:line)}; margin: 8px 0 24px; line-height: 1px; font-size: 1px"}
      {@rest}
    >
      &#8202;
    </div>
    """
  end

  attr :initials, :string, required: true, doc: "the letters in the round avatar"
  attr :rest, :global
  slot :inner_block, required: true, doc: "the sentence beside the avatar"

  @doc """
  A person and what they did: a round avatar with initials and a sentence beside it, above the heading.

  ## Example

      <.byline initials="CA">
        <.emphasis>Carlos</.emphasis> invited you to <.emphasis>Acme</.emphasis>.
      </.byline>
  """
  @spec byline(map()) :: Phoenix.LiveView.Rendered.t()
  def byline(assigns) do
    assigns = assign(assigns, :person, Style.tone(:person))

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 20px"
      {@rest}
    >
      <tbody>
        <tr>
          <td style="width: 56px; vertical-align: middle">
            <span style={"display: inline-block; width: 44px; height: 44px; line-height: 44px; border-radius: 99px; background: #{@person.bg}; color: #{@person.ink}; text-align: center; font-family: #{Style.mono()}; font-size: 14px"}>{@initials}</span>
          </td>
          <td style={"vertical-align: middle; font-family: #{Style.sans()}; font-size: 15px; line-height: 1.5; color: #{Style.color(:muted)}"}>
            {render_slot(@inner_block)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
