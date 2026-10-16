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
      assert desc =~ ~s(data-density="compact")
      assert desc =~ "group-data-[density=compact]/dt:py-1.5"
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

  describe "DataTable around the rows" do
    defp around(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            rows: @rows,
            density: :comfortable,
            density_label: nil,
            loading: false,
            loading_label: nil,
            error: nil,
            empty_text: nil,
            selectable: false,
            toolbar: false,
            footer: false,
            empty_slot: false
          },
          extra
        )

      rendered_to_string(~H"""
      <DataTable.data_table
        id="t"
        label="People"
        rows={@rows}
        density={@density}
        density_label={@density_label}
        loading={@loading}
        loading_label={@loading_label}
        error={@error}
        empty_text={@empty_text}
        selectable={@selectable}
        select_all_label="a"
        select_row_label="b"
        selected_label="c"
        clear_label="d"
      >
        <:col :let={row} label="Name">{row.name}</:col>
        <:col :let={row} label="Count">{row.n}</:col>
        <:toolbar :if={@toolbar}><input id="search" type="search" /></:toolbar>
        <:footer :if={@footer}><span>1-2 of 33</span></:footer>
        <:empty :if={@empty_slot}>Nobody.</:empty>
        <:error_action><button id="retry" type="button">Retry</button></:error_action>
        <:density_icon>ROWS</:density_icon>
      </DataTable.data_table>
      """)
    end

    test "the toolbar sits above the table and the footer below it, and neither exists without a slot" do
      html = around(%{toolbar: true, footer: true})

      {toolbar, _} = :binary.match(html, ~s(id="search"))
      {table, _} = :binary.match(html, "<table")
      {footer, _} = :binary.match(html, "1-2 of 33")
      assert toolbar < table and table < footer

      plain = around()
      refute plain =~ ~s(id="search")
      refute plain =~ "1-2 of 33"
      refute plain =~ "data-density-toggle"
    end

    test "the density toggle is drawn at the end of the toolbar when it has a label, and says which is on" do
      html = around(%{density_label: "Compact rows"})

      assert html =~ "data-density-toggle"
      assert html =~ ~s(aria-label="Compact rows")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ "ROWS"
      assert html =~ ~s(data-density="comfortable")

      compact = around(%{density_label: "Compact rows", density: :compact})
      assert compact =~ ~s(aria-pressed="true")
      assert compact =~ ~s(data-density="compact")
    end

    test "the cells follow the density of the table, so the toggle needs no redraw" do
      html = around()

      assert html =~ "py-3"
      assert html =~ "group-data-[density=compact]/dt:py-1.5"
      assert html =~ "group/dt"
    end

    test "loading draws skeleton rows, hides the rows and is named once" do
      html = around(%{loading: true, loading_label: "Loading people"})

      assert html =~ ~r/role="status" class="sr-only">\s*Loading people/
      assert html =~ ~s(aria-busy="true")
      assert length(Regex.scan(~r/animate-shimmer/, html)) == 10
      assert html =~ ~r/<tbody[^>]*hidden/
      assert html =~ ~r/<tbody aria-hidden="true">/
    end

    test "the number of skeleton rows is an attribute and a selectable table gets a box column too" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DataTable.data_table
          id="t"
          label="L"
          rows={[]}
          loading
          loading_label="Loading"
          loading_rows={2}
          selectable
          select_all_label="a"
          select_row_label="b"
          selected_label="c"
          clear_label="d"
        >
          <:col :let={row} label="Name">{row.name}</:col>
        </DataTable.data_table>
        """)

      assert length(Regex.scan(~r/animate-shimmer/, html)) == 4
    end

    test "loading needs its label" do
      assert_raise ArgumentError, ~r/loading_label/, fn -> around(%{loading: true}) end
    end

    test "an error replaces the rows with an alert and the action under it" do
      html = around(%{error: "Could not load the list"})

      assert html =~ ~r/role="alert"/
      assert html =~ "Could not load the list"
      assert html =~ ~s(id="retry")
      assert html =~ ~r/<tbody[^>]*hidden/
      refute html =~ "animate-shimmer"
    end

    test "no error draws no alert, and loading wins over an error" do
      refute around() =~ ~s(role="alert")

      both = around(%{error: "Broke", loading: true, loading_label: "Loading"})
      refute both =~ ~s(role="alert")
      assert both =~ "animate-shimmer"
    end

    test "the empty state is the slot, or the text of the attribute, or nothing" do
      assert around(%{rows: [], empty_slot: true}) =~ "Nobody."
      assert around(%{rows: [], empty_text: "No people yet"}) =~ "No people yet"

      both = around(%{rows: [], empty_slot: true, empty_text: "No people yet"})
      assert both =~ "Nobody."
      refute both =~ "No people yet"

      assert around(%{rows: []}) =~ ~r/id="t-empty"/
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
