defmodule DevactionUI.InputGroupVariantsTest do
  @moduledoc "The floating label, the spinner of a field that asks the server and the checked frame."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.InputGroup

  test "a floating label names the field and stands in for the placeholder" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="name" floating_label="Project name" placeholder="ignored" />
      """)

    assert html =~ "input-group input-floating"
    refute html =~ "input-floating-inside"
    assert html =~ ~s(<span class="input-float">)
    assert html =~ ~s(<label for="name" class="input-float-label">Project name</label>)
    assert html =~ ~s(placeholder=" ")
    refute html =~ "ignored"
  end

  test "the floating label can sit inside a taller field, after an icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="amount" floating_label="Amount" floating={:inside} value="12,500">
        <:icon><svg /></:icon>
      </InputGroup.input_group>
      """)

    assert html =~ "input-floating input-floating-inside"
    assert html =~ ~s(value="12,500")
    assert html =~ ~r/input-icon.*input-float/s
  end

  test "without a floating label the field is the plain input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="plain" placeholder="Type" />
      """)

    refute html =~ "input-float"
    assert html =~ ~s(placeholder="Type")
  end

  test "busy_label adds the spinner that shows while LiveView waits, beside the actions" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="q" type="search" busy_label="Searching" phx-debounce="300">
        <:action>
          <InputGroup.input_action label="Clear">x</InputGroup.input_action>
        </:action>
      </InputGroup.input_group>
      """)

    assert html =~ ~s(<span class="input-busy">)
    assert html =~ "Searching"
    assert html =~ ~s(<span class="input-actions">)
    assert html =~ ~s(phx-debounce="300")
  end

  test "a held loading replaces the busy spinner and the actions" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="q" busy_label="Searching" loading loading_label="Checking">
        <:action>
          <InputGroup.input_action label="Clear">x</InputGroup.input_action>
        </:action>
      </InputGroup.input_group>
      """)

    assert html =~ "Checking"
    refute html =~ "input-busy"
    refute html =~ "input-actions"
  end

  test "valid draws the checked frame" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputGroup.input_group id="slug" value="sge" valid />
      """)

    assert html =~ "input-group input-valid"
  end
end
