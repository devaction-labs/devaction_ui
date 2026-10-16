defmodule DevactionUI.StepsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Steps

  defp render_steps(current) do
    assigns = %{current: current}

    rendered_to_string(~H|<.steps labels={["A", "B", "C"]} current={@current} />|)
  end

  test "the connector after a finished step is ink and the ones after are plain" do
    html = render_steps(2)

    assert length(String.split(html, "h-px min-w-6 flex-1 bg-ink")) == 2
    assert length(String.split(html, "h-px min-w-6 flex-1 bg-line")) == 2
  end

  test "the whole row is 13px and the current label is semibold" do
    html = render_steps(2)

    assert html =~ "text-[13px]"
    refute html =~ "text-sm"
    assert html =~ "font-semibold text-ink"
  end

  test "a step to come has the pending border" do
    assert render_steps(1) =~ "border border-done-cell"
  end

  test "a current past the last finishes every step and below 1 leaves them all to come" do
    done = render_steps(9)
    assert length(String.split(done, "✓")) == 4
    refute done =~ "aria-current"

    todo = render_steps(0)
    refute todo =~ "✓"
    refute todo =~ "aria-current"
  end

  test "the done icon slot replaces the check" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.steps labels={["A", "B"]} current={2}>
        <:done_icon>OK</:done_icon>
      </.steps>
      """)

    assert html =~ "OK"
    refute html =~ "✓"
  end
end
