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
end
