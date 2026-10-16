defmodule DevactionUI.DataTableVariantsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{DataTable, Pagination}

  @rows [
    %{id: 1, name: "Ana", group: "a", n: 10},
    %{id: 2, name: "Bruno", group: "a", n: 20},
    %{id: 3, name: "Carla", group: "b", n: 5}
  ]

  defp render_table(extra) do
    assigns = %{rows: @rows, extra: extra}

    rendered_to_string(~H"""
    <DataTable.data_table
      id="t"
      label="People"
      rows={@rows}
      select_all_label="a"
      select_row_label="b"
      selected_label="c"
      clear_label="d"
      {@extra}
    >
      <:col :let={row} label="Name" primary>{row.name}</:col>
      <:col :let={row} label="Count" align={:end} mono>{row.n}</:col>
      <:expanded :let={row}>detail of {row.name}</:expanded>
      <:action :let={row}>menu {row.id}</:action>
      <:group :let={{key, rows}}>group {key} of {length(rows)}</:group>
      <:tfoot>
        <tr>
          <td>Total</td>
        </tr>
      </:tfoot>
    </DataTable.data_table>
    """)
  end

  describe "variations" do
    test "the scrolling box is a named region the keyboard can focus, with or without pinned columns" do
      html = render_table(expand_label: "Show", action_label: "Actions")

      assert html =~ ~r/<div[^>]*role="region"[^>]*tabindex="0"[^>]*aria-label="People"/
    end

    test "variant, striped and stack are data attributes of the root, which the CSS reads" do
      html =
        render_table(
          variant: :minimal,
          striped: true,
          stack: true,
          expand_label: "Show",
          action_label: "Actions"
        )

      assert html =~ ~s(data-variant="minimal")
      assert html =~ "data-striped"
      assert html =~ "data-stack"
    end

    test "a column takes align, mono and primary, and every other cell carries its label" do
      html = render_table(expand_label: "Show", action_label: "Actions")

      assert html =~ ~s(data-align="end")
      assert html =~ "data-mono"
      assert html =~ "data-primary"
      assert html =~ ~s(data-label="Count")
      refute html =~ ~s(data-label="Name")
    end

    test "the expanded slot draws a chevron and a hidden detail row per row" do
      html = render_table(expand_label: "Show", action_label: "Actions")

      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="t-row-1-detail")
      assert html =~ ~s(id="t-row-1-detail")
      assert html =~ "data-expanded-row"
      assert html =~ "detail of Ana"
      assert html =~ ~s(aria-label="Show")
    end

    test "the action slot is the last cell, pinned to the end with sticky_actions" do
      plain = render_table(expand_label: "Show", action_label: "Actions")
      pinned = render_table(expand_label: "Show", action_label: "Actions", sticky_actions: true)

      assert plain =~ "menu 1"
      assert plain =~ "data-actions"
      refute plain =~ ~s(data-sticky="end")
      assert pinned =~ ~s(data-sticky="end")
      assert pinned =~ ~s(data-pinned)
    end

    test "group_by puts a group row before each run of rows, and tfoot is the totals" do
      html =
        render_table(
          group_by: & &1.group,
          expand_label: "Show",
          action_label: "Actions"
        )

      assert html =~ "group a of 2"
      assert html =~ "group b of 1"
      assert length(Regex.scan(~r/data-group-row/, html)) == 2
      assert html =~ "<tfoot>"
      assert html =~ "Total"
    end

    test "colspan counts the extra cells" do
      html = render_table(expand_label: "Show", action_label: "Actions", rows: [])
      assert html =~ ~s(colspan="4")
    end

    test "the slots that need a label raise without it" do
      assert_raise ArgumentError, ~r/action_label/, fn -> render_table([]) end

      assert_raise ArgumentError, ~r/expand_label/, fn ->
        render_table(action_label: "Actions")
      end
    end
  end

  describe "Pagination range" do
    test "draws from, to and total with the noun" do
      assigns = %{path: &"/p?page=#{&1}"}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination
          page={4}
          pages={12}
          total={143}
          per_page={12}
          noun="reviews"
          summary_label="__FROM__-__TO__ of __TOTAL__ __NOUN__"
          path={@path}
          label="Pages"
          previous="Back"
          next="Forward"
        />
        """)

      assert html =~ "37-48 of 143 reviews"
      assert html =~ ~s(aria-current="page")
    end

    test "the last page ends at the total, and a single page still draws the range" do
      assert Pagination.range(%{
               page: 12,
               total: 143,
               per_page: 12,
               noun: "x",
               summary_label: "__FROM__-__TO__"
             }) == "133-143"

      assigns = %{path: &"/p?page=#{&1}"}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination
          page={1}
          pages={1}
          total={5}
          per_page={20}
          summary_label="__FROM__-__TO__ of __TOTAL__"
          path={@path}
          label="Pages"
          previous="Back"
          next="Forward"
        />
        """)

      assert html =~ "1-5 of 5"
      refute html =~ "<nav"
    end

    test "without the data there is no range" do
      assert Pagination.range(%{page: 1}) == nil
    end
  end
end
