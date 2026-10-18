defmodule DevactionUI.Modal do
  @moduledoc """
  A dialog for a decision that interrupts: confirm, tell that something worked, fill a short form. To edit
  without losing the context use `DevactionUI.Drawer`; to ask before something that cannot be undone use
  `danger_dialog/1`.

  The LiveView decides when it is there (`:if={@open}`). It takes the focus in, keeps it inside, closes with Esc
  and, unless it is `dismissible={false}`, with a click outside; the focus goes back to the button that opened it
  when that button used `open/1`. Sizes: `:sm` 400, `:md` 520 (default), `:lg` 720. A tall body scrolls inside
  the panel, between the header and the footer.

  While it is open the `DevactionUI.Overlay` hook locks the scroll of the page and makes everything around it
  `inert` (put `data-overlay-keep` on what has to stay usable, such as a toast region). Overlays stack: Esc
  closes only the one on top. The stacking order, from the bottom: a popover in place `z-40`, a tooltip
  `z-50`, a `DevactionUI.Drawer` `z-60`, a modal `z-70` (so a modal opened from a drawer is over it), a popover
  with `portal` `z-80`; a toast region of the app has to be above that.

  The body is whatever goes in the default slot and the actions go in `footer`:

      <Modal.modal id="rename" on_close="close" close_label="Close">
        <:close_icon><.icon name="x" /></:close_icon>
        <:title>Rename the project</:title>
        <:subtitle>The new name shows to the whole team.</:subtitle>
        <input name="name" />
        <:footer><button>Cancel</button><button>Save</button></:footer>
      </Modal.modal>

  With `centered` the icon tile, the title and the text sit in the middle and the footer buttons too: the
  success variant, usually with `tone={:ok}`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  The command for the button that opens a modal: it remembers the focus, then pushes `event`. Closing puts the
  focus back there. The same as `DevactionUI.Drawer.open/1`.
  """
  defdelegate open(event_or_js), to: DevactionUI.Drawer

  @doc "Opens a `lazy` modal in the browser, with no round trip. The same as `DevactionUI.Drawer.show/1`."
  defdelegate show(id), to: DevactionUI.Drawer

  @doc "Closes a `lazy` modal in the browser. The same as `DevactionUI.Drawer.hide/1`."
  defdelegate hide(id), to: DevactionUI.Drawer

  @doc "The command that closes: gives the focus back, then runs `on_close` (an event name or a `JS` command)."
  @spec close(String.t() | JS.t()) :: JS.t()
  def close(%JS{} = js), do: JS.pop_focus(js)
  def close(event) when is_binary(event), do: JS.pop_focus() |> JS.push(event)

  attr :id, :string, required: true

  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "400, 520 or 720 px wide"

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

  attr :lazy, :boolean,
    default: false,
    doc:
      "always rendered, hidden, and opened in the browser by `show/1`; see `DevactionUI.Drawer` on opening on the client"

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
      class="fixed inset-0 z-[70] flex items-center justify-center p-4"
      phx-hook="DevactionUI.Overlay"
      hidden={@lazy}
      data-close={DevactionUI.Drawer.dismiss(@on_close, @id, @lazy)}
      phx-mounted={mounted(@lazy, @focus, @id)}
      {@rest}
    >
      <div
        class="modal-backdrop"
        phx-click={@dismissible && DevactionUI.Drawer.dismiss(@on_close, @id, @lazy)}
        aria-hidden="true"
      />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={@subtitle != [] && "#{@id}-subtitle"}
        class={["modal relative z-50", size_class(@size), @class]}
      >
        <div class={["modal-header", @centered && "flex-col items-center text-center"]}>
          <span :if={@icon != []} class={["modal-icon", tone_class(@tone)]}>
            {render_slot(@icon)}
          </span>
          <div class="flex min-w-0 flex-1 flex-col gap-1.5">
            <h2
              id={"#{@id}-title"}
              class={[
                "m-0 font-semibold text-ink",
                @centered && "text-xl",
                not @centered && "text-lg"
              ]}
            >
              {render_slot(@title)}
            </h2>
            <div
              :if={@subtitle != []}
              id={"#{@id}-subtitle"}
              class="m-0 text-sm leading-[1.55] text-ink-2"
            >
              {render_slot(@subtitle)}
            </div>
          </div>
          <button
            :if={@close_label}
            type="button"
            aria-label={@close_label}
            phx-click={DevactionUI.Drawer.dismiss(@on_close, @id, @lazy)}
            class="-mt-1.5 -mr-2 flex size-9.5 flex-none items-center justify-center rounded-[10px] bg-transparent text-muted outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {render_slot(@close_icon)}
          </button>
        </div>
        <div :if={@inner_block != []} class="modal-body">{render_slot(@inner_block)}</div>
        <div :if={@footer != []} class={["modal-footer", @centered && "justify-center"]}>
          {render_slot(@footer)}
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp mounted(true, _focus, _id), do: JS.ignore_attributes(["hidden"])
  defp mounted(false, focus, id), do: focus(focus, id)

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
end
