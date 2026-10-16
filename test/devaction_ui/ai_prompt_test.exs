defmodule DevactionUI.AiPromptTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.AiPrompt

  defp has?(html, selector),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.count() > 0

  test "the field is required, so an empty send stays in the browser" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send">
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "#p-input[required]:not([disabled])")
    assert has?(html, "#p button[type=submit]:not([disabled])")
    refute has?(html, "#p[aria-busy]")
  end

  test "loading marks the form busy and turns the send button off" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send" loading>
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "#p[aria-busy=true] button[type=submit][disabled]")
    assert has?(html, "#p-input:not([disabled])")
  end

  test "disabled locks the field and the button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send" disabled>
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "#p-input[disabled]")
    assert has?(html, "#p button[type=submit][disabled]")
  end

  test "the target goes to the submit" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send" target="#box">
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "#p[phx-submit=ask][phx-target='#box']")
  end

  test "streaming swaps send for a stop button that sends the stop event to the target" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt
        id="p"
        event="ask"
        label="Ask"
        send_label="Send"
        streaming
        on_stop="halt"
        stop_label="Stop"
        target="#box"
      >
        <:icon>↑</:icon>
        <:stop>■</:stop>
      </AiPrompt.ai_prompt>
      """)

    assert has?(
             html,
             "#p[aria-busy=true] button[data-stop][type=button][phx-click=halt][phx-target='#box'][aria-label=Stop]"
           )

    refute has?(html, "#p button[type=submit]")
  end

  test "streaming without a stop event only turns the send button off" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send" streaming>
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "#p[aria-busy=true] button[type=submit][disabled]")
    refute has?(html, "#p button[data-stop]")
  end

  test "a stop event needs a name for the button" do
    assigns = %{}

    assert_raise ArgumentError, ~r/stop_label/, fn ->
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send" on_stop="halt">
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)
    end
  end

  test "attachments sit between the dot and the field" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send">
        <:icon>↑</:icon>
        <:attachments><span id="chip">a.pdf</span></:attachments>
      </AiPrompt.ai_prompt>
      """)

    assert html =~ ~r/bg-ai.*id="chip".*id="p-input"/s

    refute has?(
             rendered_to_string(~H"""
             <AiPrompt.ai_prompt id="p" event="ask" label="Ask" send_label="Send">
               <:icon>↑</:icon>
             </AiPrompt.ai_prompt>
             """),
             "#chip"
           )
  end

  test "the pill and its button are tokens that swap together in the dark theme" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <AiPrompt.ai_prompt
        id="p"
        event="ask"
        label="Ask"
        send_label="Send"
        value="x"
        placeholder="Ask"
        class="mine"
      >
        <:icon>↑</:icon>
      </AiPrompt.ai_prompt>
      """)

    assert has?(html, "form#p.bg-ink.text-on-primary.mine")
    assert has?(html, "#p button.bg-card.text-ink")
    assert has?(html, "#p-input[value=x][placeholder=Ask]")
    refute html =~ "#"
  end
end
