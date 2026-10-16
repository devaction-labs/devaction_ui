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
      select_all_label="Select all"
      select_row_label="Select row"
      selected_label="__COUNT__ selected"
      clear_label="Clear"
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
    test "a stream makes the body a stream and shows the empty state on its own" do
      assigns = %{stream: Phoenix.LiveView.LiveStream.new(:rows, 0, @rows, [])}

      html =
        rendered_to_string(~H"""
        <DataTable.data_table
          id="t"
          label="L"
          rows={@stream}
          select_all_label="a"
          select_row_label="b"
          selected_label="c"
          clear_label="d"
        >
          <:col :let={row} label="Name" key="name">{row.name}</:col>
          <:empty>None</:empty>
        </DataTable.data_table>
        """)

      assert html =~ ~s(phx-update="stream")
      assert html =~ ~s(id="t-empty")
      assert html =~ "only:table-row"
    end

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

    test "the boxes are the library's 20px checkbox, the rows say aria-selected and the tint is .03" do
      assigns = %{rows: @rows, sort: nil, selectable: true, density: :comfortable}

      html =
        rendered_to_string(
          ~H|<.table rows={@rows} sort={@sort} selectable={@selectable} density={@density} />|
        )

      assert length(Regex.scan(~r/class="checkbox"/, html)) == 3
      refute html =~ "accent-"
      assert length(Regex.scan(~r/aria-selected="false"/, html)) == 2
      assert html =~ "has-[input:checked]:bg-ink/[.03]"
      assert html =~ "max-h-[300px]"
      assert html =~ "px-3.5"
      assert html =~ ~s(bg-on-primary/25)
    end

    test "the rows named in `selected` start ticked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DataTable.data_table
          id="t"
          label="L"
          rows={[%{id: 1, name: "Ana"}, %{id: 2, name: "Bruno"}]}
          selectable
          selected={[2]}
          select_all_label="a"
          select_row_label="b"
          selected_label="c"
          clear_label="d"
        >
          <:col :let={row} label="Name" key="name">{row.name}</:col>
        </DataTable.data_table>
        """)

      assert length(Regex.scan(~r/data-select-row[^>]* checked/, html)) == 1
      assert html =~ ~r/id="t-row-2"[^>]*aria-selected="true"/s
      assert html =~ ~r/id="t-row-1"[^>]*aria-selected="false"/s
    end

    test "the sort arrows come from the slots, with a glyph when there is none, and the sorted header is ink" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <DataTable.data_table
          id="t"
          label="L"
          rows={@rows}
          sort={{"name", :asc}}
          on_sort="sort"
          select_all_label="a"
          select_row_label="b"
          selected_label="c"
          clear_label="d"
        >
          <:col :let={row} label="Name" key="name" sortable>{row.name}</:col>
          <:col :let={row} label="Count" key="n" sortable>{row.n}</:col>
          <:sort_asc_icon>UP</:sort_asc_icon>
          <:sort_desc_icon>DOWN</:sort_desc_icon>
        </DataTable.data_table>
        """)

      assert html =~ "UP"
      refute html =~ "DOWN"
      refute html =~ "↑"
      assert html =~ "↕"
      assert length(Regex.scan(~r/ text-ink"/, html)) == 1
    end

    test "a column with a hidden label keeps it for screen readers" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <DataTable.data_table
          id="t"
          label="L"
          rows={@rows}
          select_all_label="a"
          select_row_label="b"
          selected_label="c"
          clear_label="d"
        >
          <:col :let={row} label="Name">{row.name}</:col>
          <:col :let={_row} label="Actions" hide_label>x</:col>
        </DataTable.data_table>
        """)

      assert html =~ ~r/<span class="sr-only">\s*Actions\s*<\/span>/
      refute html =~ ~r/<span class="sr-only">\s*Name/
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
        <Kanban.kanban
          drop_label="Drop here"
          full_label="Limit reached"
          moved_label="Moved to __COLUMN__"
          hint_label="Alt and the arrows move the card"
          id="k"
          label="Tasks"
        >
          <:column id="todo" title="To do" count={1} tone={:info}>
            <Kanban.card id="a">First</Kanban.card>
          </:column>
          <:column id="doing" title="Doing" wip={2} count={0} />
          <:footer column="todo"><button>New task</button></:footer>
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

    test "the keyboard hint is read after each card, the columns are lists and the dot and the footer are the column's" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kanban.kanban
          drop_label="Drop here"
          full_label="Limit reached"
          moved_label="Moved to __COLUMN__"
          hint_label="Alt and the arrows move the card"
          id="k"
          label="Tasks"
        >
          <:column id="todo" title="To do" count={1} tone={:info}>
            <Kanban.card id="a">First</Kanban.card>
          </:column>
          <:column id="doing" title="Doing" />
          <:footer column="todo"><button>New task</button></:footer>
        </Kanban.kanban>
        """)

      assert html =~
               ~r/<p id="k-hint" class="sr-only">\s*Alt and the arrows move the card\s*<\/p>/

      assert html =~ ~s(data-hint-id="k-hint")
      assert length(Regex.scan(~r/role="list"/, html)) == 2
      assert html =~ ~s(role="listitem")
      assert length(Regex.scan(~r/size-2 shrink-0 rounded-full/, html)) == 1
      assert html =~ "bg-learn"
      assert length(Regex.scan(~r/New task/, html)) == 1
      assert html =~ "text-xs"
      assert html =~ "border-muted-2"
    end

    test "a card is focusable, dragged by pointer events and carries the id the event reports" do
      assigns = %{}
      html = rendered_to_string(~H|<Kanban.card id="card-9">Do it</Kanban.card>|)
      refute html =~ "draggable"
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(data-card-id="card-9")
      assert html =~ ~s(id="card-9")
      assert html =~ "touch-manipulation"
      assert html =~ "data-[dragging]:opacity-40"
      refute html =~ "rgba"
    end

    test "the texts and the event come from the caller, and the live region survives redraws" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kanban.kanban
          full_label="Limit reached"
          id="k"
          label="Tarefas"
          event="mover"
          drop_label="Solte aqui"
          moved_label="Movido para __COLUMN__"
          hint_label="Alt e as setas movem o cartão"
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
