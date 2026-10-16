defmodule DevactionUI.PanelTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Panel

  test "the wrap holds a bordered card in the card colour" do
    assigns = %{}
    html = rendered_to_string(~H|<.panel>Inside</.panel>|)

    assert html =~ "rounded-wrap bg-wrap p-1.5"
    assert html =~ "rounded-card border border-line bg-card"
    assert html =~ "p-6 gap-5"
    assert html =~ "Inside"
  end

  test "the id is optional" do
    assigns = %{}

    refute rendered_to_string(~H|<.panel>x</.panel>|) =~ "id="
    assert rendered_to_string(~H|<.panel id="p">x</.panel>|) =~ ~s(id="p")
  end

  test "the label names the section" do
    assigns = %{}
    assert rendered_to_string(~H|<.panel label="Summary">x</.panel>|) =~ ~s(aria-label="Summary")
  end

  test "inner_class replaces the padding and class goes on the wrap" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.panel class="max-w-md" inner_class="p-4 gap-2">x</.panel>|)

    assert html =~ ~r/class="rounded-wrap bg-wrap p-1.5 max-w-md"/
    assert html =~ "p-4 gap-2"
    refute html =~ "p-6"
  end

  test "size sets the padding and the gap of the card" do
    for {size, expected} <- [sm: "p-[22px] gap-3.5", md: "p-6 gap-5", lg: "p-[26px] gap-5"] do
      assigns = %{size: size}
      assert rendered_to_string(~H|<.panel size={@size}>x</.panel>|) =~ expected
    end

    assigns = %{}
    html = rendered_to_string(~H|<.panel size={:lg} inner_class="p-2">x</.panel>|)
    assert html =~ "p-2"
    refute html =~ "p-[26px]"
  end

  test "global attributes reach the section" do
    assigns = %{}
    html = rendered_to_string(~H|<.panel data-x="1" phx-click="go">x</.panel>|)

    assert html =~ ~s(data-x="1")
    assert html =~ ~s(phx-click="go")
  end

  test "the eyebrow is the mono caption" do
    assigns = %{}
    html = rendered_to_string(~H|<.eyebrow class="mb-2" id="e">Open</.eyebrow>|)

    assert html =~ "font-mono text-xs uppercase tracking-[0.08em] text-muted mb-2"
    assert html =~ ~s(id="e")
    assert html =~ "Open"
  end

  test "the duplicate empty box is gone in favour of EmptyState" do
    refute function_exported?(DevactionUI.Panel, :empty, 1)
  end
end
