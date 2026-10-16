defmodule DevactionUI.Drawer do
  @moduledoc """
  A panel at the side of the screen to edit without leaving it: a profile, a task, an item of a contract. The
  default is floating (12 px from the edges, rounded, with a footer that stays); it can sit docked against the
  edge, come from the left, and on a phone it is a sheet that rises from the bottom, with a handle. The variant
  `:sheet` is that bottom sheet at any width.

  The LiveView decides when it is there (`:if={@editing}`); the drawer takes the focus in, keeps it inside
  (`Phoenix.Component.focus_wrap/1`), closes with Esc, the close button and a click outside, and hands the
  focus back to the button that opened it when that button used `open/1`. Widths: 384, 480 (default) and 640.

  While it is open the `DevactionUI.Overlay` hook locks the scroll of the page and makes everything around it
  `inert` (put `data-overlay-keep` on what has to stay usable, such as a toast region). Overlays stack: Esc
  closes only the one on top. The stacking order, from the bottom: a popover in place `z-40`, a tooltip `z-50`,
  the drawer `z-60`, a `DevactionUI.Modal` `z-70` (so a modal opened from a drawer is over it), a popover with
  `portal` `z-80`; a toast region of the app has to be above that.

  On a phone, and at any width with `variant={:sheet}`, the drawer is a sheet from the bottom with a handle that
  closes it when dragged down (a short drag springs back; with `prefers-reduced-motion` it does not animate).
  The width is 384 (`:sm`), 480 (`:md`, the default, `min(30rem, 100vw - 1.5rem)`) or 640 (`:lg`). The actions
  of the footer are the caller's: the canvas draws Cancel as a 44 px quiet button with no border.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  The command for the button that opens a drawer or a modal: it remembers the focus, then pushes `event`.
  Closing (any way the component offers) puts the focus back there.
  """
  @spec open(String.t() | JS.t()) :: JS.t()
  def open(%JS{ops: ops}), do: %JS{ops: JS.push_focus().ops ++ ops}
  def open(event) when is_binary(event), do: JS.push_focus() |> JS.push(event)

  attr :id, :string, required: true
  attr :variant, :atom, values: [:floating, :docked, :sheet], default: :floating
  attr :side, :atom, values: [:right, :left], default: :right
  attr :size, :atom, values: [:sm, :md, :lg], default: :md, doc: "384, 480 or 640 px wide"

  attr :on_close, :any,
    required: true,
    doc: "an event name or a `JS` command, run on Esc, the close button and a click outside"

  attr :close_label, :string, required: true
  attr :class, :any, default: nil
  slot :close_icon, required: true
  slot :title, required: true
  slot :subtitle
  slot :inner_block, required: true, doc: "the body, which scrolls on its own"
  slot :footer, doc: "the actions, which stay at the bottom"

  attr :rest, :global

  def drawer(assigns) do
    ~H"""
    <div
      id={@id}
      class="drawer-root"
      phx-hook="DevactionUI.Overlay"
      data-close={close(@on_close)}
      phx-mounted={JS.focus_first(to: "##{@id}-panel")}
      {@rest}
    >
      <div class="drawer-backdrop" phx-click={close(@on_close)} aria-hidden="true" />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={@subtitle != [] && "#{@id}-subtitle"}
        class={[
          "drawer",
          @variant == :docked && "drawer-docked",
          @variant == :sheet && "drawer-sheet",
          @side == :left && "drawer-left",
          size_class(@size),
          @class
        ]}
      >
        <div
          data-handle
          class={[
            "flex flex-none cursor-grab touch-none justify-center pt-2.5 pb-2 active:cursor-grabbing",
            @variant != :sheet && "hidden max-sm:flex"
          ]}
          aria-hidden="true"
        >
          <span class="h-1 w-10 rounded-full bg-done" />
        </div>
        <div class="drawer-header">
          <div class="flex min-w-0 flex-1 flex-col gap-1">
            <h2 id={"#{@id}-title"} class="m-0 text-xl font-semibold tracking-[-0.01em] text-ink">
              {render_slot(@title)}
            </h2>
            <div :if={@subtitle != []} id={"#{@id}-subtitle"} class="m-0 text-[15px] text-muted">
              {render_slot(@subtitle)}
            </div>
          </div>
          <button
            type="button"
            aria-label={@close_label}
            phx-click={close(@on_close)}
            class="-mt-2 -mr-2 flex size-10 flex-none items-center justify-center rounded-[10px] bg-transparent text-muted outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {render_slot(@close_icon)}
          </button>
        </div>
        <div class="drawer-body">{render_slot(@inner_block)}</div>
        <div :if={@footer != []} class="drawer-footer">{render_slot(@footer)}</div>
      </.focus_wrap>
    </div>
    """
  end

  defp size_class(:sm), do: "drawer-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "drawer-lg"

  defp close(%JS{} = js), do: JS.pop_focus(js)
  defp close(event) when is_binary(event), do: JS.pop_focus() |> JS.push(event)
end
