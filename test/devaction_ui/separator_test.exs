defmodule DevactionUI.SeparatorTest do
  @moduledoc "The separator: plain, labelled, vertical, decorative, and the inline row of facts."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Separator

  test "a plain line is a separator" do
    assigns = %{}
    html = rendered_to_string(~H|<Separator.separator />|)

    assert html =~ ~s(role="separator")
    assert html =~ "h-px w-full bg-line"
    refute html =~ "aria-orientation"
  end

  test "a label is the accessible name and sits between two lines" do
    assigns = %{}
    html = rendered_to_string(~H|<Separator.separator label="or continue with" />|)

    assert html =~ ~s(role="separator")
    assert html =~ ~s(aria-label="or continue with")
    assert html =~ ">or continue with<"
    assert length(Regex.scan(~r/h-px flex-1 bg-line/, html)) == 2
  end

  test "vertical says its orientation" do
    assigns = %{}
    html = rendered_to_string(~H|<Separator.separator orientation={:vertical} />|)

    assert html =~ ~s(aria-orientation="vertical")
    assert html =~ "w-px self-stretch"
  end

  test "decorative hides it from assistive technology" do
    assigns = %{}
    html = rendered_to_string(~H|<Separator.separator decorative label="or" />|)

    assert html =~ ~s(role="none")
    refute html =~ "aria-label"
    refute html =~ ~s(role="separator")
  end

  test "the inline row puts a bar between facts, never before the first" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Separator.inline>
        <:item>Today</:item>
        <:item>3 PRs</:item>
        <:item>12 h logged</:item>
      </Separator.inline>
      """)

    assert length(Regex.scan(~r/h-3\.5 w-px/, html)) == 2
    assert html =~ "Today"
    assert html =~ "12 h logged"
  end
end
