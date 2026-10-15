defmodule DevactionUI.DataTest do
  @moduledoc "The markup of the table and the board. Sorting, selection and drag are checked in a browser through `/dev/ui`; the server's side is what these cover."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{DataTable, Kanban}

  @rows [%{id: "1", name: "Ana", n: 3}, %{id: "2", name: "Bruno", n: 5}]

  defp table(assigns) do
    ~H"""
    <DataTable.data_table
      id="t"
      label="People"
      rows={@rows}
      sort={@sort}
      on_sort="sort"
      selectable={@selectable}
      density={@density}
    >
      <:col :let={row} label="Name" key="name" sortable>{row.name}</:col>
      <:col :let={row} label="Count" key="n" class="font-mono">{row.n}</:col>
      <:bulk><a href="/x">Approve</a></:bulk>
      <:empty>Nobody.</:empty>
    </DataTable.data_table>
    """
  end

  describe "DataTable" do
    test "draws the caption, the headers and a row per item" do
      assigns = %{rows: @rows, sort: nil, selectable: false, density: :comfortable}

      html =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={@sort} selectable={@selectable} density={@density} />|
        )

      assert html =~ ~r/<caption class="sr-only">People<\/caption>/
      assert html =~ ~s(id="t-row-1")
      assert html =~ ~s(id="t-row-2")
      assert html =~ "Ana" and html =~ "Bruno"
      refute html =~ "data-select-row"
    end

    test "a sortable header is a button that sends the key, and says its state with aria-sort" do
      assigns = %{rows: @rows, sort: {"name", :asc}, selectable: false, density: :comfortable}

      html =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={@sort} selectable={@selectable} density={@density} />|
        )

      assert html =~ ~s(phx-value-key="name")
      assert html =~ ~s(aria-sort="ascending")
      assert html =~ "↑"
      refute html =~ ~s(phx-value-key="n")

      desc =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={{"name", :desc}} selectable={false} density={:compact} />|
        )

      assert desc =~ ~s(aria-sort="descending")
      assert desc =~ "py-1.5"
    end

    test "selection adds a checkbox per row, a tri-state header one and a hidden bulk bar" do
      assigns = %{rows: @rows, sort: nil, selectable: true, density: :comfortable}

      html =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={@sort} selectable={@selectable} density={@density} />|
        )

      assert length(Regex.scan(~r/data-select-row/, html)) == 2
      assert html =~ "data-select-all"
      assert html =~ ~s(name="selected[]")
      assert html =~ ~s(value="2")
      assert html =~ ~r/data-bulk\s+hidden/
      assert html =~ "Approve"
      assert html =~ "phx-hook"
    end

    test "says so when there is nothing to list" do
      assigns = %{rows: [], sort: nil, selectable: true, density: :comfortable}

      html =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={@sort} selectable={@selectable} density={@density} />|
        )

      assert html =~ "Nobody."
      assert html =~ ~s(colspan="3")
    end
  end

  describe "Kanban" do
    test "a column per slot with its title, its limit and the cards in it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kanban.kanban id="k" label="Tasks">
          <:column id="todo" title="To do" count={1}>
            <Kanban.card id="a">First</Kanban.card>
          </:column>
          <:column id="doing" title="Doing" wip={2} count={0} />
        </Kanban.kanban>
        """)

      assert html =~ ~s(data-column="todo")
      assert html =~ ~s(data-column="doing")
      assert html =~ ~s(data-wip="2")
      assert html =~ "/2"
      assert html =~ ~s(aria-label="Tasks")
      assert html =~ ~s(data-event="move_card")
      assert html =~ "First"
    end

    test "a card is draggable, focusable and carries the id the event reports" do
      assigns = %{}
      html = rendered_to_string(~H|<Kanban.card id="card-9">Do it</Kanban.card>|)
      assert html =~ ~s(draggable="true")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(data-card-id="card-9")
      assert html =~ ~s(id="card-9")
    end

    test "the texts and the event come from the caller, and the live region survives redraws" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kanban.kanban
          id="k"
          label="Tarefas"
          event="mover"
          drop_label="Solte aqui"
          moved_label="Movido para __COLUMN__"
        >
          <:column id="a" title="A" />
        </Kanban.kanban>
        """)

      assert html =~ ~s(data-event="mover")
      assert html =~ "Solte aqui"
      assert html =~ ~s(data-moved-label="Movido para __COLUMN__")
      assert html =~ ~r/id="k-live"[^>]*phx-update="ignore"|phx-update="ignore"[^>]*id="k-live"/s
    end
  end
end
