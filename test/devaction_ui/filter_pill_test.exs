defmodule DevactionUI.FilterPillTest do
  @moduledoc "The round pills of a filter bar: on or off, with a ×, and the dashed one that adds."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.FilterPill

  describe "filter_pill" do
    test "is a toggle button that sends its value and says whether it is on" do
      assigns = %{}

      off = rendered_to_string(~H|<FilterPill.filter_pill label="Hub API" event="toggle" />|)
      assert off =~ ~s(aria-pressed="false")
      assert off =~ ~s(phx-click="toggle")
      assert off =~ ~s(phx-value-value="Hub API")
      assert off =~ "border-line-strong"
      assert off =~ "rounded-full"
      assert off =~ "h-[30px]"
      refute off =~ "data-active"

      on =
        rendered_to_string(
          ~H|<FilterPill.filter_pill label="SGE" value="sge" event="toggle" active />|
        )

      assert on =~ ~s(aria-pressed="true")
      assert on =~ ~s(phx-value-value="sge")
      assert on =~ ~s(data-active="true")
      assert on =~ "bg-ink text-on-primary"
    end

    test "the warn tone is the amber one and gives way to ink when it is on" do
      assigns = %{}

      warn = rendered_to_string(~H|<FilterPill.filter_pill label="Only AI" tone={:warn} />|)
      assert warn =~ "border-warn-line bg-warn-bg text-warn-fg"

      active =
        rendered_to_string(~H|<FilterPill.filter_pill label="Only AI" tone={:warn} active />|)

      assert active =~ "bg-ink"
      refute active =~ "bg-warn-bg"
    end

    test "has no × unless it can be removed" do
      assigns = %{}

      html = rendered_to_string(~H|<FilterPill.filter_pill label="SGE" />|)
      assert length(Regex.scan(~r/<button/, html)) == 1
      refute html =~ "×"
    end

    test "the × is its own button, named by the pill, with its own event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterPill.filter_pill
          label="SGE"
          event="toggle"
          remove_event="drop"
          remove_label="Remove %{label}"
          target="#bar"
        />
        """)

      assert length(Regex.scan(~r/<button/, html)) == 2
      assert html =~ ~s(aria-label="Remove SGE")
      assert html =~ ~s(phx-click="drop")
      assert html =~ ~s(phx-value-value="SGE")
      assert length(Regex.scan(~r/phx-target="#bar"/, html)) == 2
      assert html =~ "×"
    end

    test "the icons come from the slots and the id, class and attributes reach the pill" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterPill.filter_pill
          id="p1"
          label="SGE"
          class="extra"
          data-key="k"
          remove_event="drop"
          remove_label="Remove %{label}"
        >
          <:icon>ICON</:icon>
          <:remove_icon>X-ICON</:remove_icon>
        </FilterPill.filter_pill>
        """)

      assert html =~ ~s(id="p1")
      assert html =~ "extra"
      assert html =~ ~s(data-key="k")
      assert html =~ "ICON"
      assert html =~ "X-ICON"
      refute html =~ "×"
    end
  end

  describe "add_pill" do
    test "is the dashed button that adds a filter" do
      assigns = %{}

      html = rendered_to_string(~H|<FilterPill.add_pill label="Filter" event="add" />|)

      assert html =~ "border-dashed border-line-dashed"
      assert html =~ ~s(phx-click="add")
      assert html =~ ~s(type="button")
      assert html =~ ~r/>\s*\+\s*<\/span>\s*Filter/
    end

    test "takes an icon in place of the plus" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterPill.add_pill label="Filter" class="extra" data-x="1">
          <:icon>PLUS-ICON</:icon>
        </FilterPill.add_pill>
        """)

      assert html =~ "PLUS-ICON"
      assert html =~ "extra"
      assert html =~ ~s(data-x="1")
      refute html =~ ~r/>\s*\+\s*</
    end
  end
end
