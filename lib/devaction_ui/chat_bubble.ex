defmodule DevactionUI.ChatBubble do
  @moduledoc """
  One message of the conversation with the AI. The AI speaks on the left, with its mark beside the bubble
  and the corner nearest the mark squared; the person speaks on the right in ink. A message that did
  something (a lesson sent, a task made) is drawn `:highlight`, in the amber of "the AI did this".
  """
  use Phoenix.Component

  attr :from, :atom, values: [:ai, :me], required: true
  attr :highlight, :boolean, default: false, doc: "an AI message that did something"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :avatar, doc: "the AI's mark, drawn by the caller; only used for `:ai`"
  slot :inner_block, required: true

  def chat_bubble(%{from: :ai} = assigns) do
    ~H"""
    <div class={["flex items-start gap-2", @class]} {@rest}>
      <span :if={@avatar != []} class="shrink-0" aria-hidden="true">{render_slot(@avatar)}</span>
      <p class={[
        "m-0 rounded-[4px_14px_14px_14px] px-3 py-2.5 text-sm leading-[1.45]",
        (@highlight && "border border-tag-warn-line bg-tag-warn-bg text-tag-warn-text") ||
          "bg-wrap text-ink"
      ]}>
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end

  def chat_bubble(%{from: :me} = assigns) do
    ~H"""
    <div class={["flex justify-end", @class]} {@rest}>
      <p class="m-0 rounded-[14px_4px_14px_14px] bg-ink px-3 py-2.5 text-sm leading-[1.45] text-on-primary">
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end
end
