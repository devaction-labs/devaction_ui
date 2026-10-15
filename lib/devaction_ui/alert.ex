defmodule DevactionUI.Alert do
  @moduledoc """
  A short message under a form or at the top of a screen: it worked, the AI did something, here is how it
  is, this failed. Smaller than a `Callout`: one line of title and a line or two of text, with an icon.
  `kind: :risk` is announced as an alert; the others as a status.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :kind, :atom, values: [:ok, :ai, :info, :risk], default: :info
  attr :title, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :icon, doc: "the icon, drawn by the caller"

  def alert(assigns) do
    assigns = assign(assigns, :tone, Tone.from_kind(assigns.kind))

    ~H"""
    <div
      role={role(@kind)}
      class={["flex gap-3 rounded-[14px] border px-4 py-3.5 text-sm", Tone.surface(@tone), @class]}
      {@rest}
    >
      <span :if={@icon != []} class={["mt-0.5 shrink-0", Tone.text(@tone)]} aria-hidden="true">
        {render_slot(@icon)}
      </span>
      <div class="flex min-w-0 flex-col gap-0.5">
        <p class={["m-0 font-semibold", Tone.text(@tone)]}>{@title}</p>
        <div :if={@inner_block != []} class="text-ink-2">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  defp role(:risk), do: "alert"
  defp role(_kind), do: "status"
end
