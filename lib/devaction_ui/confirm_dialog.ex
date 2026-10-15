defmodule DevactionUI.ConfirmDialog do
  @moduledoc """
  A modal that asks before something that cannot be taken back, such as publishing a review to GitHub.
  The LiveView decides when it is there (`:if={@confirming}`); it takes the focus in, keeps it inside
  (`Phoenix.Component.focus_wrap/1`), closes with Esc or the close button, and gives the focus back to
  what opened it. The two buttons are the caller's, so the confirming one can say what it does
  ("Publish", not "OK").
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :eyebrow, :string, default: nil, doc: "a small mono line above the title"

  attr :on_cancel, :any,
    required: true,
    doc: "an event name or a `JS` command, run on Esc, the close button and the backdrop"

  attr :close_label, :string, required: true
  attr :class, :any, default: nil
  slot :close_icon, required: true
  slot :inner_block, required: true, doc: "what will happen, in a sentence or two"
  slot :actions, required: true, doc: "the cancel and the confirm buttons"

  attr :rest, :global

  def confirm_dialog(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
      phx-mounted={JS.focus_first(to: "##{@id}-panel")}
      phx-window-keydown={cancel(@on_cancel)}
      phx-key="escape"
      {@rest}
    >
      <div class="absolute inset-0" phx-click={cancel(@on_cancel)} aria-hidden="true" />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        class={[
          "relative w-full max-w-[520px] overflow-hidden rounded-[18px] bg-card shadow-[0_24px_60px_rgba(24,24,27,0.25)]",
          @class
        ]}
      >
        <div class="flex items-start justify-between gap-3 px-6 pt-[22px]">
          <div class="flex flex-col gap-1.5">
            <span :if={@eyebrow} class="font-mono text-[11px] tracking-[0.08em] text-muted">
              {@eyebrow}
            </span>
            <h2 id={"#{@id}-title"} class="m-0 text-xl font-semibold text-ink">{@title}</h2>
          </div>
          <button
            type="button"
            aria-label={@close_label}
            phx-click={cancel(@on_cancel)}
            class="flex size-9 items-center justify-center rounded-[10px] border border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-2 focus-visible:ring-ink/20"
          >
            {render_slot(@close_icon)}
          </button>
        </div>
        <div class="mx-6 mt-3 text-sm leading-normal text-ink-2">{render_slot(@inner_block)}</div>
        <div class="mt-5 flex justify-end gap-2.5 border-t border-line bg-wrap px-6 py-3.5">
          {render_slot(@actions)}
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp cancel(%JS{} = js), do: JS.pop_focus(js)
  defp cancel(event) when is_binary(event), do: JS.pop_focus() |> JS.push(event)
end
