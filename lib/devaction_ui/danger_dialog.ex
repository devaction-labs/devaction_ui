defmodule DevactionUI.DangerDialog do
  @moduledoc """
  The dialog before something that cannot be undone: stop monitoring a repository, delete a project. The red
  button stays locked until the person types the name of the thing, so it is never a reflex. A click outside does
  not close it, only Esc, Cancel and the close button do.

  The LiveView keeps what was typed (`typed`) and learns of each keystroke through `on_type` (a `phx-keyup`);
  `confirmed?/2` says whether the button is unlocked, and the server checks it again when the event arrives.
  After it is done the caller can offer to undo with a toast.
  """
  use Phoenix.Component

  import DevactionUI.Modal

  @doc "Whether what was typed is the name of the thing, ignoring the spaces at the ends."
  @spec confirmed?(String.t() | nil, String.t()) :: boolean()
  def confirmed?(typed, expected) when is_binary(typed), do: String.trim(typed) == expected
  def confirmed?(_typed, _expected), do: false

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "what must be typed: the name of the resource"
  attr :typed, :string, default: "", doc: "what the person has typed so far"
  attr :on_type, :string, required: true, doc: "the event of `phx-keyup` on the field"
  attr :on_confirm, :string, required: true, doc: "the event of the red button"
  attr :on_close, :any, required: true, doc: "a `JS` command or an event name run when it closes"

  attr :confirm_label, :string,
    required: true,
    doc: "what the red button does: \"Stop monitoring\", not \"OK\""

  attr :cancel_label, :string, required: true
  attr :close_label, :string, required: true

  attr :type_label, :string,
    required: true,
    doc: "the sentence over the field, with the name drawn in it by the caller"

  slot :icon, required: true
  slot :close_icon, required: true
  slot :title, required: true
  slot :inner_block, required: true, doc: "what will be lost and what stays"

  attr :rest, :global

  def danger_dialog(assigns) do
    assigns = assign(assigns, :unlocked?, confirmed?(assigns.typed, assigns.name))

    ~H"""
    <.modal
      id={@id}
      size={:sm}
      tone={:risk}
      dismissible={false}
      focus={"##{@id}-typed"}
      on_close={@on_close}
      close_label={@close_label}
      {@rest}
    >
      <:icon>{render_slot(@icon)}</:icon>
      <:close_icon>{render_slot(@close_icon)}</:close_icon>
      <:title>{render_slot(@title)}</:title>
      <:subtitle>{render_slot(@inner_block)}</:subtitle>
      <label class="flex flex-col gap-1.5 text-sm text-ink-2">
        {@type_label}
        <input
          id={"#{@id}-typed"}
          type="text"
          name="typed"
          value={@typed}
          autocomplete="off"
          phx-keyup={@on_type}
          class="h-11 rounded-xl border border-line-strong bg-card px-3.5 text-[15px] text-ink outline-none focus:border-ink focus:ring-4 focus:ring-ink/10"
        />
      </label>
      <:footer>
        <button
          id={"#{@id}-cancel"}
          type="button"
          phx-click={@on_close}
          class="h-10 rounded-[10px] border border-line-strong bg-card px-4 text-sm font-medium text-ink hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {@cancel_label}
        </button>
        <button
          id={"#{@id}-confirm"}
          type="button"
          aria-disabled={to_string(not @unlocked?)}
          phx-click={@unlocked? && @on_confirm}
          class="h-10 rounded-[10px] bg-missing px-4 text-sm font-semibold text-on-primary hover:opacity-90 focus-visible:ring-4 focus-visible:ring-missing/30 aria-disabled:cursor-not-allowed aria-disabled:opacity-40"
        >
          {@confirm_label}
        </button>
      </:footer>
    </.modal>
    """
  end
end
