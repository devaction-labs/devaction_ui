defmodule DevactionUI.ConfirmDialog do
  @moduledoc """
  A modal that asks before something that cannot be taken back, such as publishing a review to GitHub. It is
  a `DevactionUI.Modal` with the question as the title, the explanation as the text and the two buttons in
  the footer, so it takes the focus in, keeps it inside, closes with Esc and a click outside (unless
  `dismissible={false}`) and gives the focus back to what opened it. The buttons are the caller's, so the
  confirming one can say what it does ("Publish", not "OK"). There is no close button in the corner unless
  `close_label` is given.
  """
  use Phoenix.Component

  import DevactionUI.Modal

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :size, :atom, values: [:sm, :md, :lg], default: :md

  attr :tone, :atom,
    values: [:neutral, :info, :ok, :warn, :risk],
    default: :warn,
    doc: "the tone of the icon tile"

  attr :dismissible, :boolean, default: true, doc: "a click outside closes it"

  attr :on_cancel, :any,
    required: true,
    doc: "an event name or a `JS` command, run on Esc, the close button and a click outside"

  attr :close_label, :string,
    default: nil,
    doc: "when given, a close button is drawn in the corner"

  attr :class, :any, default: nil
  slot :icon, doc: "the mark in the tile before the title"
  slot :close_icon
  slot :inner_block, required: true, doc: "what will happen, in a sentence or two"
  slot :actions, required: true, doc: "the cancel and the confirm buttons"

  attr :rest, :global

  def confirm_dialog(assigns) do
    ~H"""
    <.modal
      id={@id}
      size={@size}
      tone={@tone}
      dismissible={@dismissible}
      on_close={@on_cancel}
      close_label={@close_label}
      class={@class}
      {@rest}
    >
      <:icon :if={@icon != []}>{render_slot(@icon)}</:icon>
      <:close_icon :if={@close_icon != []}>{render_slot(@close_icon)}</:close_icon>
      <:title>{@title}</:title>
      <:subtitle>{render_slot(@inner_block)}</:subtitle>
      <:footer>{render_slot(@actions)}</:footer>
    </.modal>
    """
  end
end
