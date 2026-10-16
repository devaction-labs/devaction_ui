defmodule DevactionUI.ScrollAreaTest do
  @moduledoc "The scroll area, and the pinned columns, toolbar and home link that came with the layout theme."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Breadcrumb, DataTable, PageHeader, ScrollArea}

  describe "scroll area" do
    test "is a hooked region whose hook leaves the edge marks alone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ScrollArea.scroll_area id="sa" label="Projects" data-extra="x">CONTENT</ScrollArea.scroll_area>
        """)

      assert html =~ ~s(id="sa")
      assert html =~ ~s(phx-hook="DevactionUI.ScrollArea")
      assert html =~ "data-more-left"
      assert html =~ "data-scrolled-y"
      assert html =~ "data-viewport"
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="Projects")
      assert html =~ ~s(data-extra="x")
      assert html =~ "CONTENT"
    end

    test "limits are CSS variables, written only when given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ScrollArea.scroll_area id="sa" max_h="560px" edge_right="56px">C</ScrollArea.scroll_area>
        """)

      assert html =~ ~s(style="--max-h: 560px; --edge-right: 56px")
      refute html =~ "--edge-left"

      plain = rendered_to_string(~H|<ScrollArea.scroll_area id="sa">C</ScrollArea.scroll_area>|)
      refute plain =~ "style="
      refute plain =~ "role="
    end

    test "bare drops the frame" do
      assigns = %{}

      html =
        rendered_to_string(~H|<ScrollArea.scroll_area id="sa" bare>C</ScrollArea.scroll_area>|)

      assert html =~ "data-bare"
    end
  end

  describe "breadcrumb home" do
    test "starts the trail with a named link and an icon from the caller" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb
          label="Here"
          home="/"
          home_label="Start"
          items={[%{label: "Work", to: "/w"}, %{label: "Projects"}]}
        >
          <:home_icon>HOMEICON</:home_icon>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~r/<a[^>]*href="\/"[^>]*aria-label="Start"/s
      assert html =~ "HOMEICON"
      assert length(Regex.scan(~r/<li/, html)) == 3
    end

    test "falls back to a glyph, and needs a label" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Breadcrumb.breadcrumb label="Here" home="/" home_label="Start" items={[%{label: "A"}]} />|
        )

      assert html =~ "⌂"

      assert_raise ArgumentError, ~r/home_label/, fn ->
        rendered_to_string(
          ~H|<Breadcrumb.breadcrumb label="Here" home="/" items={[%{label: "A"}]} />|
        )
      end
    end

    test "without home the trail is what it was" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Breadcrumb.breadcrumb label="Here" items={[%{label: "A"}, %{label: "B"}]} />|
        )

      refute html =~ "⌂"
      assert length(Regex.scan(~r/<li/, html)) == 2
    end
  end

  describe "page header toolbar" do
    test "draws a row under the tabs with the count at its end" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <PageHeader.page_header id="h">
          <:title>T</:title>
          <:tabs>TABS</:tabs>
          <:toolbar>SEARCH</:toolbar>
          <:toolbar_end>12 results</:toolbar_end>
        </PageHeader.page_header>
        """)

      assert html =~ "SEARCH"
      assert html =~ "12 results"
      assert html =~ "ms-auto"
    end

    test "has no toolbar row when it has no toolbar" do
      assigns = %{}

      html =
        rendered_to_string(~H|<PageHeader.page_header id="h">
  <:title>T</:title>
</PageHeader.page_header>|)

      refute html =~ "ms-auto"
    end
  end

  describe "data table pinned columns" do
    defp table(assigns) do
      ~H"""
      <DataTable.data_table
        id="t"
        label="People"
        rows={[%{id: 1, name: "Ana"}]}
        selectable={@selectable}
        select_all_label="all"
        select_row_label="row"
        selected_label="__COUNT__"
        clear_label="clear"
      >
        <:col :let={row} label="Name" sticky={@first}>{row.name}</:col>
        <:col :let={row} label="Other">{row.id}</:col>
        <:col :let={row} label="Actions" hide_label sticky={@last}>{row.id}</:col>
      </DataTable.data_table>
      """
    end

    test "pins the first column and the actions, and hooks the scroller" do
      assigns = %{selectable: false, first: :start, last: :end}

      html =
        rendered_to_string(~H|<.table selectable={@selectable} first={@first} last={@last} />|)

      assert html =~ ~s(data-sticky="start")
      assert html =~ ~s(data-sticky="end")
      assert html =~ ~s(phx-hook="DevactionUI.ScrollArea")
      assert html =~ ~s(id="t-scroll")
      assert html =~ "data-pinned"
      assert html =~ "data-more-left"
      assert length(Regex.scan(~r/data-sticky="start"/, html)) == 2
    end

    test "pins the checkbox column along with the first one" do
      assigns = %{selectable: true, first: :start, last: nil}

      html =
        rendered_to_string(~H|<.table selectable={@selectable} first={@first} last={@last} />|)

      assert html =~ "data-select-cell"
      assert length(Regex.scan(~r/data-sticky="start"/, html)) == 4
    end

    test "a table with nothing pinned is as before: no hook, no marks" do
      assigns = %{selectable: true, first: nil, last: nil}

      html =
        rendered_to_string(~H|<.table selectable={@selectable} first={@first} last={@last} />|)

      refute html =~ "data-sticky"
      refute html =~ "DevactionUI.ScrollArea"
      refute html =~ "data-pinned"
    end
  end
end
