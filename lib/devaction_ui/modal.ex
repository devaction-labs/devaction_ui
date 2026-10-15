defmodule DevactionUI.Modal do
  @moduledoc """
  A dialog for a decision that interrupts: confirm, tell that something worked, fill a short form. To edit
  without losing the context use `DevactionUI.Drawer`; to ask before something that cannot be undone use
  `danger_dialog/1`.

  The LiveView decides when it is there (`:if={@open}`). It takes the focus in, keeps it inside, closes with Esc
  and, unless it is `dismissible={false}`, with a click outside; the focus goes back to the button that opened it
  when that button used `DevactionUI.Drawer.open/1`. Sizes: `:sm` 400, `:md` 520 (default), `:lg` 720.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :size, :atom, values: [:sm, :md, :lg], default: :md

  attr :tone, :atom,
    values: [:neutral, :info, :ok, :warn, :risk],
    default: :neutral,
    doc: "the tone of the icon tile"

  attr :centered, :boolean,
    default: false,
    doc: "the icon, the title and the text in the middle, for a success"

  attr :dismissible, :boolean, default: true, doc: "a click outside closes it"

  attr :on_close, :any,
    required: true,
    doc: "an event name or a `JS` command, run on Esc, the close button and a click outside"

  attr :close_label, :string,
    default: nil,
    doc: "when given, a close button is drawn in the corner"

  attr :focus, :string,
    default: nil,
    doc: "a selector of what takes the focus when it opens; the first control when left out"

  attr :class, :any, default: nil
  slot :icon, doc: "the mark in the tile before the title"
  slot :close_icon
  slot :title, required: true
  slot :subtitle
  slot :inner_block, doc: "the body, between the header and the footer"
  slot :footer, doc: "the actions, at the end"

  attr :rest, :global

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
      phx-mounted={focus(@focus, @id)}
      phx-window-keydown={close(@on_close)}
      phx-key="escape"
      {@rest}
    >
      <div
        class="modal-backdrop"
        phx-click={@dismissible && close(@on_close)}
        aria-hidden="true"
      />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        class={["modal relative z-50", size_class(@size), @class]}
      >
        <div class={["modal-header", @centered && "flex-col items-center text-center"]}>
          <span :if={@icon != []} class={["modal-icon", tone_class(@tone)]}>
            {render_slot(@icon)}
          </span>
          <div class="flex min-w-0 flex-1 flex-col gap-1.5">
            <h2 id={"#{@id}-title"} class="m-0 text-xl font-semibold tracking-[-0.02em] text-ink">
              {render_slot(@title)}
            </h2>
            <p :if={@subtitle != []} class="m-0 text-sm leading-normal text-ink-2">
              {render_slot(@subtitle)}
            </p>
          </div>
          <button
            :if={@close_label}
            type="button"
            aria-label={@close_label}
            phx-click={close(@on_close)}
            class="flex size-9 flex-none items-center justify-center rounded-[10px] border border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {render_slot(@close_icon)}
          </button>
        </div>
        <div :if={@inner_block != []} class="px-6.5 pb-5">{render_slot(@inner_block)}</div>
        <div :if={@footer != []} class={["modal-footer", @centered && "justify-center"]}>
          {render_slot(@footer)}
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp focus(nil, id), do: JS.focus_first(to: "##{id}-panel")
  defp focus(selector, _id), do: JS.focus(to: selector)

  defp size_class(:sm), do: "modal-sm"
  defp size_class(:md), do: "modal-md"
  defp size_class(:lg), do: "modal-lg"

  defp tone_class(:neutral), do: "border-line bg-wrap text-ink-2"
  defp tone_class(:info), do: "border-tag-info-line bg-tag-info-bg text-tag-info-text"
  defp tone_class(:ok), do: "border-tag-ok-line bg-tag-ok-bg text-tag-ok-text"
  defp tone_class(:warn), do: "border-tag-warn-line bg-tag-warn-bg text-tag-warn-text"
  defp tone_class(:risk), do: "border-tag-risk-line bg-tag-risk-bg text-tag-risk-text"

  defp close(%JS{} = js), do: JS.pop_focus(js)
  defp close(event) when is_binary(event), do: JS.pop_focus() |> JS.push(event)
end
