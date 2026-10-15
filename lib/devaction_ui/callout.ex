defmodule DevactionUI.Callout do
  @moduledoc """
  A tinted block that says something to the reader: a note, what the AI did, a tip, a warning, a decision.
  Color is never alone: it always carries a title or an `icon` slot, and an `:alert` role when it is urgent.

  `kind` is the canvas's name (`:note`, `:ai`, `:tip`, `:warning`, `:decision`) or a plain tone (`:risk`,
  `:warn`, `:ok`, `:info`, `:neutral`). With `title`, the title is bold on its own line; `actions` is a row
  for buttons under the body.
  """

  use Phoenix.Component

  alias DevactionUI.Tone

  attr :kind, :atom, default: :note
  attr :title, :string, default: nil

  attr :role, :string,
    default: nil,
    doc: "`alert` for something urgent, `status` for a change the reader should hear"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :icon, doc: "the icon, drawn by the caller in the tone of the callout"
  slot :actions

  def callout(assigns) do
    assigns = assign(assigns, :tone, Tone.from_kind(assigns.kind))

    ~H"""
    <div
      role={@role}
      class={[
        "flex gap-3 rounded-2xl border p-[18px] text-sm leading-normal",
        Tone.surface(@tone),
        @class
      ]}
      {@rest}
    >
      <span
        :if={@icon != []}
        class={[
          "flex size-8 shrink-0 items-center justify-center rounded-lg bg-card/70",
          Tone.text(@tone)
        ]}
        aria-hidden="true"
      >
        {render_slot(@icon)}
      </span>
      <div class="flex min-w-0 flex-1 flex-col gap-2">
        <p :if={@title} class={["m-0 font-semibold", Tone.text(@tone)]}>{@title}</p>
        <div class="text-ink-2">{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex flex-wrap gap-2 pt-1">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end
end
