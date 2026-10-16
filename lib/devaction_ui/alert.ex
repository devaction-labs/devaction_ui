defmodule DevactionUI.Alert do
  @moduledoc """
  A short message under a form or at the top of a screen: it worked, the AI did something, here is how it
  is, this failed. One line of title and a line or two of text, with an icon, in the darker text of its tone.
  `kind: :risk` is announced as an alert; the others as a status.

  The boundary with `DevactionUI.Callout`: an alert is a notice that says one thing and has no way out; a
  callout is a block the reader acts on, with a title, a longer body and `actions` under it.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :kind, :atom,
    values: [:ok, :ai, :info, :warn, :risk, :neutral],
    default: :info,
    doc: "the tone it is drawn in; `:ai` is the amber of what the AI did"

  attr :title, :string, required: true, doc: "the bold first line"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "the line or two of text under the title"
  slot :icon, doc: "the icon, drawn by the caller"

  @doc "A tinted notice with a title, an optional icon and an optional body."
  @spec alert(map()) :: Phoenix.LiveView.Rendered.t()
  def alert(assigns) do
    assigns = assign(assigns, :tone, Tone.from_kind(assigns.kind))

    ~H"""
    <div
      role={role(@kind)}
      class={[
        "flex gap-3 rounded-[14px] border px-4 py-3.5 text-sm leading-[1.45]",
        Tone.surface(@tone),
        Tone.strong(@tone),
        @class
      ]}
      {@rest}
    >
      <span :if={@icon != []} class="mt-0.5 shrink-0" aria-hidden="true">
        {render_slot(@icon)}
      </span>
      <div class="flex min-w-0 flex-col gap-0.5">
        <p class="m-0 font-semibold">{@title}</p>
        <div :if={@inner_block != []}>{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  defp role(:risk), do: "alert"
  defp role(_kind), do: "status"
end
