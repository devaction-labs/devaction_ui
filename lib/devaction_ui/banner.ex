defmodule DevactionUI.Banner do
  @moduledoc """
  A full-width strip at the top of a page or a section that tells the whole screen something: news, a degraded
  service, an expiring plan, a lost connection. A bold lead and a line of text, an icon in front, one action
  link at the end and a button to dismiss it.

  Four tones: `:info`, `:warning`, `:critical` and `:offline` (solid ink, the strongest strip). `:critical` is
  announced at once (`role="alert"`); the others politely (`role="status"`). It is not a toast: it stays until
  the person dismisses it or the cause is gone, and the server decides which, so a dismiss is an event
  (`on_dismiss`, a string or a `%JS{}`, sent to `target` when there is one) and the page stops rendering it.

  The icon, the action and the dismiss icon are slots and every word is an attribute: the library knows no
  icon set and no language. Differs from `DevactionUI.Alert`, which sits inside a page under a form and has
  neither an action nor a way out.
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  attr :tone, :atom,
    values: [:info, :warning, :critical, :offline],
    default: :info,
    doc: "`:critical` is announced as an alert, the others as a status"

  attr :title, :string, default: nil, doc: "the bold lead, such as `Novelty:`"

  attr :on_dismiss, :any,
    default: nil,
    doc: "the event (a string or a `%JS{}`) of the dismiss button; without it there is no button"

  attr :dismiss_label, :string,
    default: nil,
    doc: "the name of the dismiss button; needed with `on_dismiss`"

  attr :target, :any,
    default: nil,
    doc: "the LiveComponent (`@myself`) that receives `on_dismiss`"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "the line of text after the lead"
  slot :icon, doc: "the icon in front, drawn by the caller"
  slot :action, doc: "a link or button at the end, drawn underlined"
  slot :dismiss_icon, doc: "the icon of the dismiss button, such as a cross"

  @doc "A full-width strip with a lead, a text, an action and a dismiss button."
  @spec banner(map()) :: Phoenix.LiveView.Rendered.t()
  def banner(%{on_dismiss: dismiss, dismiss_label: nil}) when not is_nil(dismiss),
    do: raise(ArgumentError, "banner: `on_dismiss` needs a `dismiss_label`")

  def banner(assigns) do
    ~H"""
    <div
      role={role(@tone)}
      data-tone={@tone}
      class={[
        "flex min-h-12 items-center gap-3 rounded-xl border px-4 py-2 text-sm",
        surface(@tone),
        @class
      ]}
      {@rest}
    >
      <span :if={@icon != []} aria-hidden="true" class="size-[18px] shrink-0 [&>*]:size-full">
        {render_slot(@icon)}
      </span>
      <span class="min-w-0">
        <b :if={@title} class="font-semibold">{@title}</b> {render_slot(@inner_block)}
      </span>
      <span class="ml-auto flex shrink-0 items-center gap-2.5">
        <span
          :for={action <- @action}
          class="font-medium underline underline-offset-[3px] [&>*]:rounded [&>*]:outline-none [&>*]:focus-visible:ring-2 [&>*]:focus-visible:ring-current"
        >
          {render_slot(action)}
        </span>
        <button
          :if={@on_dismiss}
          type="button"
          aria-label={@dismiss_label}
          phx-click={@on_dismiss}
          phx-target={@target}
          class="grid size-6 place-items-center rounded-md opacity-70 outline-none hover:opacity-100 focus-visible:opacity-100 focus-visible:ring-2 focus-visible:ring-current"
        >
          <span aria-hidden="true" class="size-4 [&>*]:size-full">
            {render_slot(@dismiss_icon)}
          </span>
        </button>
      </span>
    </div>
    """
  end

  defp role(:critical), do: "alert"
  defp role(_tone), do: "status"

  defp surface(:info), do: [Tone.surface(:info), "text-banner-info"]
  defp surface(:warning), do: [Tone.surface(:warn), "text-banner-warn"]
  defp surface(:critical), do: [Tone.surface(:risk), "text-banner-risk"]
  defp surface(:offline), do: "border-ink bg-ink text-card"
end
