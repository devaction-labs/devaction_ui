defmodule DevactionUI.EmailTag do
  @moduledoc """
  The small labels of an e-mail: the mono tag that says risk, warning, suggestion or ok, a row of them with counts,
  and the larger chip that names what the e-mail is about (a repository, a week, a role).

  Five tones carry the meaning: `:risk`, `:warn`, `:info`, `:ok` and `:neutral`. The tone never stands alone: the label
  is always text, and you write it in capitals because a mail client does not always honor `text-transform`.
  Border, background and text come from one map in `DevactionUI.Email.Style`, in literal hex, because an e-mail has
  no CSS variables.
  """

  use Phoenix.Component

  alias DevactionUI.Email.Style

  @tones [:risk, :warn, :ok, :info, :neutral]

  attr :tone, :atom, values: @tones, default: :neutral, doc: "what the tag means"

  attr :size, :atom,
    values: [:sm, :md],
    default: :sm,
    doc: "`:sm` 10 px for a row of a list, `:md` 11 px for a count"

  attr :rest, :global
  slot :inner_block, required: true, doc: "the label, in capitals"

  @doc """
  A mono label with a tinted border and background.

  ## Example

      <.tag tone={:risk}>RISK</.tag>
      <.tag tone={:ok} size={:md}>TESTS OK</.tag>
  """
  @spec tag(map()) :: Phoenix.LiveView.Rendered.t()
  def tag(assigns) do
    ~H"""
    <span style={Style.tag(@tone, @size)} {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  slot :tag, required: true, doc: "a tag of the row" do
    attr :tone, :atom, values: @tones
  end

  attr :rest, :global

  @doc """
  Several tags in a line, each a little larger: the counts under a heading.

  ## Example

      <.tag_row>
        <:tag tone={:risk}>2 RISKS</:tag>
        <:tag tone={:info}>1 SUGGESTION</:tag>
      </.tag_row>
  """
  @spec tag_row(map()) :: Phoenix.LiveView.Rendered.t()
  def tag_row(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      style="border-collapse: collapse; margin: 0 0 20px"
      {@rest}
    >
      <tbody>
        <tr>
          <td :for={tag <- @tag} style="padding: 0 6px 0 0">
            <.tag tone={Map.get(tag, :tone, :neutral)} size={:md}>{render_slot(tag)}</.tag>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :tone, :atom, values: @tones, default: :neutral
  attr :rest, :global
  slot :inner_block, required: true, doc: "what the e-mail is about, in mono"

  @doc """
  The chip above the heading that names the subject: a repository and a number, a week, a role.

  ## Example

      <.chip>sge-api · #142</.chip>
      <.chip tone={:warn}>RENEWS IN 30 DAYS</.chip>
  """
  @spec chip(map()) :: Phoenix.LiveView.Rendered.t()
  def chip(assigns) do
    ~H"""
    <p style="margin: 0 0 16px" {@rest}>
      <span style={Style.chip(@tone)}>{render_slot(@inner_block)}</span>
    </p>
    """
  end
end
