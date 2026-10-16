defmodule DevactionUI.StepperTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Stepper

  @labels %{done: "done", current: "current", error: "failed", todo: "to do"}

  defp render_stepper(orientation, error_icon \\ false) do
    assigns = %{orientation: orientation, labels: @labels, error_icon: error_icon}

    rendered_to_string(~H"""
    <Stepper.stepper id="s" orientation={@orientation} state_labels={@labels}>
      <:step state={:done} label="One" help="First" />
      <:step state={:error} label="Two" />
      <:step state={:current} label="Three" />
      <:step state={:todo} label="Four" />
      <:error_icon :if={@error_icon}>ERR</:error_icon>
    </Stepper.stepper>
    """)
  end

  test "an error wins over the current step" do
    assert Stepper.states(4, 2, 2) == [:done, :error, :todo, :todo]
  end

  test "the dot of a failed step keeps its number and the label turns red" do
    for orientation <- [:horizontal, :vertical] do
      html = render_stepper(orientation)

      refute html =~ ">!<"
      assert html =~ ~r/step-dot[^>]*>\s*2\s*</
      assert html =~ "text-tag-risk-text"
    end
  end

  test "the error_icon slot replaces the number of a failed step" do
    html = render_stepper(:vertical, true)

    assert html =~ "ERR"
    refute html =~ ~r/step-dot[^>]*>\s*2\s*</
  end

  test "vertical: 24px dot, 2px rail, 13px text and the label by state" do
    html = render_stepper(:vertical)

    assert html =~ "step-dot size-6"
    assert html =~ "w-0.5"
    assert html =~ "text-[13px]"
    assert html =~ "pb-4"
    assert html =~ "font-semibold text-ink"
    assert html =~ "font-medium text-muted"
    assert html =~ "· failed"
  end

  test "a state_labels map without all four keys raises" do
    assigns = %{labels: %{done: "d", current: "c", todo: "t"}}

    assert_raise ArgumentError, ~r/state_labels needs the keys/, fn ->
      rendered_to_string(~H"""
      <Stepper.stepper id="s" state_labels={@labels}>
        <:step state={:done} label="One" />
      </Stepper.stepper>
      """)
    end
  end
end
