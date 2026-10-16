defmodule DevactionUI.EmailCallout do
  @moduledoc """
  The blocks of an e-mail that say something apart from the text: a tinted notice (this was not you, the link
  works only once) and the highlighted card that points to one thing to read next.

  Both are one-cell tables with a 12 px radius, the way a client draws them. The tints are the same five tones as
  `DevactionUI.EmailTag`; the card has its own warm one. They keep their light tint in dark mode, so the text
  inside keeps its tone color.
  """

  use Phoenix.Component

  alias DevactionUI.Email
  alias DevactionUI.Email.Style

  attr :tone, :atom,
    values: [:risk, :warn, :ok, :info, :neutral],
    default: :neutral,
    doc: "what the notice means, which sets its border, background and text"

  attr :lead, :string, default: nil, doc: "a bold first phrase, in the ink color"
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A tinted notice, with an optional bold `lead`. It keeps its light tint in dark mode, so an
  `DevactionUI.Email.emphasis/1` inside it needs `surface={:tint}`.

  ## Example

      <.callout tone={:risk} lead="Was it not you?">
        Reset your password now.
      </.callout>
  """
  @spec callout(map()) :: Phoenix.LiveView.Rendered.t()
  def callout(assigns) do
    assigns = assign(assigns, :palette, Style.tone(assigns.tone))

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px"
      {@rest}
    >
      <tbody>
        <tr>
          <td style={"padding: 14px 16px; border-radius: 12px; border: 1px solid #{@palette.line}; background: #{@palette.bg}; font-family: #{Style.sans()}; font-size: 14px; line-height: 1.55; color: #{@palette.ink}"}>
            <Email.emphasis :if={@lead} surface={:tint}>{@lead}</Email.emphasis>
            {render_slot(@inner_block)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :label, :string, required: true, doc: "the mono caption on top, in capitals"
  attr :title, :string, required: true, doc: "the bold line, which is the link"
  attr :href, :string, required: true, doc: "where the title leads"
  attr :meta, :string, required: true, doc: "the small line under the title"
  attr :rest, :global

  @doc """
  A warm card that points to one thing: a caption, a linked title and a line of detail.

  ## Example

      <.highlight
        label="SUGGESTED LESSON"
        title="Idempotency in Oban jobs"
        href="https://acme.test/lessons/42"
        meta="12 min · Elixir"
      />
  """
  @spec highlight(map()) :: Phoenix.LiveView.Rendered.t()
  def highlight(assigns) do
    assigns = assign(assigns, :palette, Style.tone(:highlight))

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px"
      {@rest}
    >
      <tbody>
        <tr>
          <td style={"padding: 16px; border-radius: 12px; border: 1px solid #{@palette.line}; background: #{@palette.bg}"}>
            <p style={"margin: 0 0 4px; font-family: #{Style.mono()}; font-size: 11px; line-height: normal; letter-spacing: 0.08em; color: #{@palette.ink}"}>
              {@label}
            </p>
            <p style={"margin: 0 0 2px; font-family: #{Style.sans()}; font-size: 15px; line-height: normal; font-weight: 600; color: #{Style.color(:ink)}"}>
              <a href={@href} style={"color: #{Style.color(:ink)}; text-decoration: none"}>{@title}</a>
            </p>
            <p style={"margin: 0; font-family: #{Style.sans()}; font-size: 13px; line-height: normal; color: #{@palette.ink}"}>
              {@meta}
            </p>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
