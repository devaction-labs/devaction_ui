defmodule DevactionUI.IconSlotsTest do
  @moduledoc "The typographic marks of the components (`×`, `✓`, `‹ ›`) are the default and a slot replaces each one."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Pagination, Pillbox, ProgressToast, Stepper, Steps}

  defp stepper(assigns) do
    ~H"""
    <Stepper.stepper
      id="s"
      orientation={:vertical}
      state_labels={%{done: "d", current: "c", error: "e", todo: "t"}}
    >
      <:done_icon :if={@icon}>DONE</:done_icon>
      <:step state={:done} label="One" />
    </Stepper.stepper>
    """
  end

  test "a finished step shows the check mark, or the slot" do
    assert rendered_to_string(stepper(%{icon: false})) =~ "✓"

    html = rendered_to_string(stepper(%{icon: true}))
    assert html =~ "DONE"
    refute html =~ "✓"
  end

  test "pagination arrows can be replaced" do
    assigns = %{path: &"/p/#{&1}"}

    html =
      rendered_to_string(~H"""
      <Pagination.pagination page={2} pages={5} path={@path} label="P" previous="Prev" next="Next">
        <:previous_icon>PREV</:previous_icon>
        <:next_icon>NEXT</:next_icon>
      </Pagination.pagination>
      """)

    assert html =~ "PREV"
    assert html =~ "NEXT"
    refute html =~ "‹"
  end

  test "steps, progress toast and pillbox keep their mark unless a slot is given" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Steps.steps labels={["a", "b"]} current={2}>
        <:done_icon>OK</:done_icon>
      </Steps.steps>
      <ProgressToast.progress_toast
        id="t"
        state={:done}
        progress={100}
        title="T"
        on_dismiss="x"
        dismiss_label="Close"
      >
        <:close_icon>CLOSE</:close_icon>
      </ProgressToast.progress_toast>
      <Pillbox.pillbox id="p" name="tags" label="Tags" placeholder="" remove_label="Remove" values={[]}>
        <:remove_icon>GONE</:remove_icon>
      </Pillbox.pillbox>
      """)

    assert html =~ "OK"
    assert html =~ "CLOSE"
    assert html =~ "GONE"
  end
end
