defmodule DevactionUI.ResizableTest do
  @moduledoc "The resizable group: its panels, its separators and what they report to assistive technology."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Resizable

  defp group(extra \\ %{}) do
    assigns = Map.merge(%{orientation: :horizontal, target: nil}, extra)

    rendered_to_string(~H"""
    <Resizable.group
      id="rz"
      label="Review"
      handle_label="Resize panels"
      orientation={@orientation}
      target={@target}
      class="h-72"
    >
      <:panel id="diff" size={58} min={20} max={80}>DIFF-BODY <span data-size-value>58</span></:panel>
      <:panel id="summary" size={42} class="bg-warn-bg">SUMMARY-BODY</:panel>
    </Resizable.group>
    """)
  end

  test "is a hooked group of panels with their bodies and their sizes" do
    html = group()

    assert html =~ ~s(phx-hook="DevactionUI.Resizable")
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="Review")
    assert html =~ "DIFF-BODY"
    assert html =~ "SUMMARY-BODY"
    assert html =~ ~s(data-size="58")
    assert html =~ ~s(style="flex: 58 1 0%")
    assert html =~ ~s(style="flex: 42 1 0%")
    assert html =~ "bg-warn-bg"
  end

  test "there is one separator between two panels, named and focusable" do
    html = group()

    assert length(Regex.scan(~r/role="separator"/, html)) == 1
    assert html =~ ~s(aria-label="Resize panels")
    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(aria-controls="rz-diff")
  end

  test "the separator of side by side panels is vertical, and the other way round" do
    assert group() =~ ~s(aria-orientation="vertical")
    assert group() =~ "cursor-col-resize"
    assert group(%{orientation: :vertical}) =~ ~s(aria-orientation="horizontal")
    assert group(%{orientation: :vertical}) =~ "cursor-row-resize"
    assert group(%{orientation: :vertical}) =~ "flex-col"
  end

  test "the separator reports the size of the panel before it and how far it can go" do
    html = group()

    assert html =~ ~s(aria-valuenow="58")
    assert html =~ ~s(aria-valuemin="20")
    assert html =~ ~s(aria-valuemax="80")
  end

  test "the other panel's limits narrow what the separator can reach" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Resizable.group id="r2" label="x" handle_label="Resize">
        <:panel id="a" size={50}>A</:panel>
        <:panel id="b" size={50} min={30}>B</:panel>
      </Resizable.group>
      """)

    assert html =~ ~s(aria-valuemin="0")
    assert html =~ ~s(aria-valuemax="70")
  end

  test "panels with no size share the group equally, and three panels have two separators" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Resizable.group id="r3" label="x" handle_label="Resize">
        <:panel id="a">A</:panel>
        <:panel id="b">B</:panel>
        <:panel id="c">C</:panel>
      </Resizable.group>
      """)

    assert html =~ ~s(style="flex: 33.33 1 0%")
    assert length(Regex.scan(~r/role="separator"/, html)) == 2
  end

  test "hands the hook the event, the way the panels lie and the limits of each panel" do
    html = group()

    assert html =~ ~s(data-event="resize")
    assert html =~ ~s(data-orientation="horizontal")
    assert html =~ ~s(data-min="20")
    assert html =~ ~s(data-max="80")
  end

  test "sends its event to the target of a LiveComponent" do
    assert group(%{target: "#panel"}) =~ ~s(phx-target="#panel")
  end

  test "the hook owns the style and the separator's values, so a patch leaves them alone" do
    html = group()

    assert html =~ "ignore_attrs"
    assert html =~ "aria-valuenow"
  end

  test "passes the caller's own attributes to the group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Resizable.group id="r4" label="x" handle_label="Resize" data-screen="review">
        <:panel id="a">A</:panel>
        <:panel id="b">B</:panel>
      </Resizable.group>
      """)

    assert html =~ ~s(data-screen="review")
  end
end
