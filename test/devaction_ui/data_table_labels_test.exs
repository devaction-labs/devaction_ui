defmodule DevactionUI.DataTableLabelsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.DataTable

  @rows [%{id: 1, name: "Ana"}, %{id: 2, name: "Bruno"}]

  defp render_table(extra) do
    assigns = %{rows: @rows, extra: extra}

    rendered_to_string(~H"""
    <DataTable.data_table id="t" label="People" rows={@rows} {@extra}>
      <:col :let={row} label="Name">{row.name}</:col>
    </DataTable.data_table>
    """)
  end

  test "a table that is not selectable needs none of the four selection labels" do
    html = render_table(%{})

    assert html =~ "Ana"
    refute html =~ "data-select-all"
  end

  test "a selectable table with every label draws the checkboxes" do
    html =
      render_table(%{
        selectable: true,
        select_all_label: "Select all",
        select_row_label: "Select row",
        selected_label: "__COUNT__ selected",
        clear_label: "Clear"
      })

    assert html =~ "data-select-all"
    assert html =~ ~s(aria-label="Select all")
    assert html =~ ~s(aria-label="Select row")
  end

  for missing <- ~w(select_all_label select_row_label selected_label clear_label)a do
    test "a selectable table raises without #{missing}" do
      labels =
        Map.delete(
          %{
            select_all_label: "a",
            select_row_label: "b",
            selected_label: "c",
            clear_label: "d"
          },
          unquote(missing)
        )

      assert_raise ArgumentError, ~r/needs a #{unquote(missing)}/, fn ->
        render_table(Map.put(labels, :selectable, true))
      end
    end
  end
end
