defmodule DevactionUI.Drawer do
  @moduledoc """
  A panel at the side of the screen to edit without leaving it: a profile, a task, an item of a contract. The
  default is floating (12 px from the edges, rounded, with a footer that stays); it can sit docked against the
  edge, come from the left, and on a phone it is a sheet that rises from the bottom, with a handle.

  The LiveView decides when it is there (`:if={@editing}`); the drawer takes the focus in, keeps it inside
  (`Phoenix.Component.focus_wrap/1`), closes with Esc, the close button and a click outside, and hands the
  focus back to the button that opened it when that button used `open/1`. Widths: 384, 480 (default) and 640.
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
  attr :variant, :atom, values: [:floating, :docked], default: :floating
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
      phx-mounted={JS.focus_first(to: "##{@id}-panel")}
      phx-window-keydown={close(@on_close)}
      phx-key="escape"
      {@rest}
    >
      <div class="drawer-backdrop" phx-click={close(@on_close)} aria-hidden="true" />
      <.focus_wrap
        id={"#{@id}-panel"}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        class={[
          "drawer",
          @variant == :docked && "drawer-docked",
          @side == :left && "drawer-left",
          size_class(@size),
          @class
        ]}
      >
        <span
          class="mx-auto mt-2 hidden h-1.5 w-10 flex-none rounded-full bg-line-strong max-sm:block"
          aria-hidden="true"
        />
        <div class="drawer-header">
          <div class="flex min-w-0 flex-1 flex-col gap-1">
            <h2 id={"#{@id}-title"} class="m-0 text-xl font-semibold tracking-[-0.02em] text-ink">
              {render_slot(@title)}
            </h2>
            <p :if={@subtitle != []} class="m-0 text-sm text-muted">{render_slot(@subtitle)}</p>
          </div>
          <button
            type="button"
            aria-label={@close_label}
            phx-click={close(@on_close)}
            class="flex size-9 flex-none items-center justify-center rounded-[10px] border border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
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
