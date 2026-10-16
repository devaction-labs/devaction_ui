defmodule DevactionUI.Callout do
  @moduledoc """
  A tinted block that says something to the reader: a note, what the AI did, a tip, a warning, a decision.
  Color is never alone: it always carries a title or an `icon` slot, and an `:alert` role when it is urgent.

  `kind` is the canvas's name (`:note`, `:ai`, `:tip`, `:warning`, `:decision`) or a plain tone (`:risk`,
  `:warn`, `:ok`, `:info`, `:neutral`). With `title`, the title is bold on its own line; `actions` is a row
  for buttons under the body. The role follows the kind: `alert` for `:risk`, `:warn` and `:warning`,
  `status` for the rest; `role` overrides it.

  The boundary with `DevactionUI.Alert`: a callout is a block the reader acts on, with a longer body and
  `actions`; an alert is the one-line notice with no way out.
  """

  use Phoenix.Component

  alias DevactionUI.Tone

  attr :kind, :atom,
    values: [:note, :ai, :tip, :warning, :decision, :risk, :warn, :ok, :info, :neutral],
    default: :note,
    doc: "the canvas's name for what it says, or a plain tone"

  attr :title, :string, default: nil

  attr :role, :string,
    default: nil,
    doc: "overrides the role the kind gives: `alert` for something urgent, `status` for a change"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :icon, doc: "the icon, drawn by the caller in the tone of the callout"
  slot :actions

  def callout(assigns) do
    assigns = assign(assigns, :tone, Tone.from_kind(assigns.kind))

    ~H"""
    <div
      role={@role || role(@kind)}
      class={[
        "flex gap-2.5 rounded-[14px] border p-[18px] text-sm leading-normal",
        Tone.surface(@tone),
        Tone.strong(@tone),
        @class
      ]}
      {@rest}
    >
      <span
        :if={@icon != []}
        class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-card/70"
        aria-hidden="true"
      >
        {render_slot(@icon)}
      </span>
      <div class="flex min-w-0 flex-1 flex-col gap-2.5">
        <p :if={@title} class="m-0 font-semibold">{@title}</p>
        <div>{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex flex-wrap gap-2">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  defp role(:risk), do: "alert"
  defp role(:warn), do: "alert"
  defp role(:warning), do: "alert"
  defp role(_kind), do: "status"
end
