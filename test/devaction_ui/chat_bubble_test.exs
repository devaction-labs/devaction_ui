defmodule DevactionUI.ChatBubbleTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.ChatBubble

  test "the bubble is a div, so it can hold blocks" do
    assigns = %{}

    for from <- [:ai, :me] do
      assigns = Map.put(assigns, :from, from)

      html =
        rendered_to_string(~H"""
        <ChatBubble.chat_bubble from={@from}>
          <p>One</p><p>Two</p>
        </ChatBubble.chat_bubble>
        """)

      refute html =~ ~r/<p[^>]*class="m-0/
      assert html =~ ~r/<div class="m-0 rounded/
    end
  end

  test "a speaker is read out and not drawn, and there is none by default" do
    assigns = %{}

    for from <- [:ai, :me] do
      assigns = Map.put(assigns, :from, from)

      named =
        rendered_to_string(~H"""
        <ChatBubble.chat_bubble from={@from} speaker="Assistant said">Hi</ChatBubble.chat_bubble>
        """)

      assert named =~ ~r/sr-only">Assistant said <\/span>Hi/

      refute rendered_to_string(
               ~H|<ChatBubble.chat_bubble from={@from}>Hi</ChatBubble.chat_bubble>|
             ) =~
               "sr-only"
    end
  end

  test "highlight is ignored for a message from me" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<ChatBubble.chat_bubble from={:me} highlight>Hi</ChatBubble.chat_bubble>|
      )

    assert html =~ "bg-ink"
    refute html =~ "bg-tag-warn-bg"
  end

  test "a highlighted AI message uses the strong text of the warn tone" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<ChatBubble.chat_bubble from={:ai} highlight>Done</ChatBubble.chat_bubble>|
      )

    assert html =~ "border-tag-warn-line bg-tag-warn-bg text-tag-warn-strong"
    refute html =~ "text-tag-warn-text"
  end

  test "the mark of the AI sits in a 28px rounded box" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <ChatBubble.chat_bubble from={:ai}>
        <:avatar>MARK</:avatar>Hi
      </ChatBubble.chat_bubble>
      """)

    assert html =~ ~r/<span[^>]*size-7[^>]*rounded-lg[^>]*bg-bubble-mark[^>]*>\s*MARK/

    refute rendered_to_string(~H|<ChatBubble.chat_bubble from={:ai}>Hi</ChatBubble.chat_bubble>|) =~
             "bg-bubble-mark"
  end
end
