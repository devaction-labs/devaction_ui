defmodule DevactionUI.ChatBubble do
  @moduledoc """
  One message of the conversation with the AI. The AI speaks on the left, with its mark beside the bubble
  and the corner nearest the mark squared; the person speaks on the right in ink. A message that did
  something (a lesson sent, a task made) is drawn `:highlight`, in the amber of "the AI did this" with the
  strong text of that tone; a message from `:me` ignores `highlight`. The mark of the AI (the `avatar` slot)
  sits in a 28px rounded box of the dark `--bubble-mark` colour.

  The bubble is a `<div>`, so the message can hold paragraphs, lists or code. Give it a `speaker` to have
  assistive technology read who is talking before the text.
  """
  use Phoenix.Component

  attr :from, :atom, values: [:ai, :me], required: true

  attr :highlight, :boolean,
    default: false,
    doc: "an AI message that did something; ignored for `:me`"

  attr :speaker, :string,
    default: nil,
    doc: "who is talking, read out before the message and not drawn"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :avatar, doc: "the AI's mark, an icon, set in a 28px box; only used for `:ai`"
  slot :inner_block, required: true, doc: "the message"

  @doc "A message of the conversation, from the AI or from the person."
  @spec chat_bubble(map()) :: Phoenix.LiveView.Rendered.t()
  def chat_bubble(%{from: :ai} = assigns) do
    ~H"""
    <div class={["flex items-start gap-2", @class]} {@rest}>
      <span
        :if={@avatar != []}
        class="flex size-7 shrink-0 items-center justify-center rounded-lg bg-bubble-mark"
        aria-hidden="true"
      >
        {render_slot(@avatar)}
      </span>
      <div class={[
        "m-0 rounded-[4px_14px_14px_14px] px-3 py-2.5 text-sm leading-[1.45]",
        (@highlight && "border border-tag-warn-line bg-tag-warn-bg text-tag-warn-strong") ||
          "bg-wrap text-ink"
      ]}>
        <span :if={@speaker} class="sr-only">{@speaker} </span>{render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  def chat_bubble(%{from: :me} = assigns) do
    ~H"""
    <div class={["flex justify-end", @class]} {@rest}>
      <div class="m-0 rounded-[14px_4px_14px_14px] bg-ink px-3 py-2.5 text-sm leading-[1.45] text-on-primary">
        <span :if={@speaker} class="sr-only">{@speaker} </span>{render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
