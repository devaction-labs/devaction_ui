defmodule DevactionUI.EmptyStepperProgressTest do
  @moduledoc "The empty states in their three ways, the stepper with the state of each step, and the progress bars."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{EmptyState, Progress, Stepper}

  describe "EmptyState" do
    test "the dashed one keeps its look" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmptyState.empty_state title="T" text="X">
          <:icon>I</:icon><:action>A</:action>
        </EmptyState.empty_state>
        """)

      assert html =~ "border-dashed"
      assert html =~ ">T<"
      assert html =~ ">A<"
    end

    test "the page one has the grid, the icon, the kicker, the text and both actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmptyState.empty_state variant={:page} kicker="PROJECTS" title="No project" text="Why">
          <:icon>I</:icon>
          <:action>MAIN</:action>
          <:secondary>SECOND</:secondary>
        </EmptyState.empty_state>
        """)

      assert html =~ ~s(class="empty)
      assert html =~ "empty-grid"
      assert html =~ "empty-icon"
      assert html =~ "PROJECTS"
      assert html =~ "MAIN"
      assert html =~ "SECOND"
      assert html =~ "Why"

      bare = rendered_to_string(~H|<EmptyState.empty_state variant={:page} title="Only" />|)
      refute bare =~ "empty-icon"
      refute bare =~ "mt-2 flex"
    end

    test "the inline one is a small row, with an action when it can be fixed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <EmptyState.empty_state variant={:inline} title="Could not load" text="GitHub did not answer">
          <:icon>I</:icon>
          <:action>RETRY</:action>
        </EmptyState.empty_state>
        """)

      assert html =~ "empty-inline"
      assert html =~ "RETRY"

      refute rendered_to_string(~H|<EmptyState.empty_state variant={:inline} title="T" />|) =~
               "mt-1.5"
    end
  end

  describe "Stepper" do
    test "the states follow where the wizard is, and an error marks its step" do
      assert Stepper.states(4, 2) == [:done, :current, :todo, :todo]
      assert Stepper.states(4, 1) == [:current, :todo, :todo, :todo]
      assert Stepper.states(3, 4) == [:done, :done, :done]
      assert Stepper.states(4, 3, 3) == [:done, :done, :error, :todo]
    end

    defp stepper(orientation) do
      assigns = %{orientation: orientation}

      rendered_to_string(~H"""
      <Stepper.stepper
        id="s"
        orientation={@orientation}
        state_labels={%{done: "done", current: "current", error: "failed", todo: "to do"}}
      >
        <:step state={:done} label="One" help="First" />
        <:step state={:current} label="Two" />
        <:step state={:error} label="Three" />
        <:step state={:todo} label="Four" />
      </Stepper.stepper>
      """)
    end

    test "horizontal: bars over dots, the current step is announced and each state is written out" do
      html = stepper(:horizontal)

      assert html =~ ~s(class="stepper)
      assert length(Regex.scan(~r/data-state=/, html)) == 4
      assert length(Regex.scan(~r/aria-current="step"/, html)) == 1
      assert html =~ "· current"
      assert html =~ "· failed"
      assert html =~ "· done"
      assert html =~ "· to do"
      assert html =~ "✓"
      refute html =~ ">!<"
      assert html =~ "First"
    end

    test "vertical: a checklist with a rail between the steps" do
      html = stepper(:vertical)

      assert html =~ "flex-col"
      assert html =~ "step-row"
      assert length(Regex.scan(~r/aria-hidden="true"/, html)) == 3
      assert html =~ "bg-ink"
      assert html =~ "text-muted"
      assert length(Regex.scan(~r/aria-current="step"/, html)) == 1
    end
  end

  describe "Progress" do
    test "the bar clamps its value and says it" do
      assigns = %{}
      html = rendered_to_string(~H|<Progress.progress label="L" value={140} />|)

      assert html =~ ~s(aria-valuenow="100")
      assert html =~ "width: 100%"

      assert rendered_to_string(~H|<Progress.progress label="L" value={-3} />|) =~
               ~s(aria-valuenow="0")
    end

    test "the segmented one fills whole pieces" do
      assert Progress.filled?(1, 4, 25)
      refute Progress.filled?(2, 4, 25)
      assert Progress.filled?(4, 4, 100)

      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Progress.progress label="L" variant={:segmented} segments={4} value={60} tone={:ok} />|
        )

      assert length(Regex.scan(~r/data-filled="true"/, html)) == 2
      assert length(Regex.scan(~r/data-filled="false"/, html)) == 2
      assert html =~ "flex gap-0.5"
    end

    test "the thin one is two pixels and the indeterminate one gives no value" do
      assigns = %{}

      assert rendered_to_string(~H|<Progress.progress label="L" variant={:thin} value={10} />|) =~
               "h-0.5"

      html = rendered_to_string(~H|<Progress.progress label="L" indeterminate />|)
      assert html =~ ~s(aria-busy="true")
      assert html =~ "animate-shimmer"
      assert html =~ "motion-reduce:animate-none"
      refute html =~ "aria-valuenow"
    end
  end
end
