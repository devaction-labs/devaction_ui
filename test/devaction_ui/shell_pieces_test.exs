defmodule DevactionUI.ShellPiecesTest do
  @moduledoc "The segmented control, the head of a page, the side menu and the command palette."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{CommandPalette, PageHeader, Segmented, Sidebar}

  defp tabindexes(html),
    do: ~r/<button[^>]*tabindex="(-?\d)"/ |> Regex.scan(html) |> Enum.map(&List.last/1)

  describe "Segmented" do
    test "is a group of toggle buttons that marks the chosen option and sends the value of a press" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="View" value="board" event="pick">
          <:option value="list" label="List" />
          <:option value="board" label="Board" count="3" />
        </Segmented.segmented>
        """)

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="View")
      assert html =~ ~s(aria-pressed="true")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ ~s(phx-click="pick")
      assert html =~ ~s(phx-value-value="list")
      assert html =~ ~r/>\s*3\s*</
      refute html =~ "bg-wrap"
      assert html =~ "font-mono text-[11px] text-muted"
      assert html =~ ~s(class="segmented )
      refute html =~ "segmented-full"
    end

    test "can be full width, small, or only icons that are still named" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="a" event="e" full size={:sm}>
          <:icon :let={option}>ICON-{option.value}</:icon>
          <:option value="a" label="Rows" icon_only />
          <:option value="b" label="Cards" icon_only />
        </Segmented.segmented>
        """)

      assert html =~ "segmented-full"
      assert html =~ "segmented-sm"
      assert html =~ ~s(aria-label="Rows")
      assert html =~ "ICON-a"
      assert html =~ "w-9"
      refute html =~ "<span>Rows</span>"
    end

    test "an option can be disabled, take a class, and patch or navigate instead of the event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="a">
          <:option value="a" label="A" patch="/list" />
          <:option value="b" label="B" navigate="/board" class="extra" disabled />
          <:option value="c" label="C" />
        </Segmented.segmented>
        """)

      assert html =~ "&quot;patch&quot;"
      assert html =~ "/list"
      assert html =~ "&quot;navigate&quot;"
      assert html =~ "/board"
      assert html =~ "extra"
      assert html =~ ~r/<button[^>]* disabled/
      refute html =~ "segmented-sm"
    end

    test "the group has the hook and only the pressed segment is in the Tab order" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="b" event="e">
          <:option value="a" label="A" />
          <:option value="b" label="B" />
          <:option value="c" label="C" />
        </Segmented.segmented>
        """)

      assert html =~ ~s(phx-hook="DevactionUI.Segmented")
      assert tabindexes(html) == ["-1", "0", "-1"]
      assert html =~ ~s(aria-pressed="true")
      refute html =~ "role=\"radio"
    end

    test "with no option chosen the first enabled one is the tab stop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="none" event="e">
          <:option value="a" label="A" disabled />
          <:option value="b" label="B" />
          <:option value="c" label="C" />
        </Segmented.segmented>
        """)

      assert tabindexes(html) == ["-1", "0", "-1"]
    end

    test "a chosen option that is disabled does not hold the tab stop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="a" event="e">
          <:option value="a" label="A" disabled />
          <:option value="b" label="B" />
        </Segmented.segmented>
        """)

      assert tabindexes(html) == ["-1", "0"]
    end

    test "the target goes to every segment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Segmented.segmented id="s" label="L" value="a" event="e" target="#box">
          <:option value="a" label="A" />
        </Segmented.segmented>
        """)

      assert html =~ ~s(phx-target="#box")
    end
  end

  describe "PageHeader" do
    test "places the breadcrumb, the title with its status, the line, the actions and the tabs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <PageHeader.page_header id="h">
          <:breadcrumb>CRUMB</:breadcrumb>
          <:title>Title</:title>
          <:status>STATUS</:status>
          <:subtitle>Sub</:subtitle>
          <:actions>ACTIONS</:actions>
          <:tabs>TABS</:tabs>
        </PageHeader.page_header>
        """)

      for part <- ~w(CRUMB Title STATUS Sub ACTIONS TABS), do: assert(html =~ part)
      assert html =~ "<h1"
      assert html =~ "page-title"
    end

    test "draws only what it is given" do
      assigns = %{}

      html =
        rendered_to_string(~H|<PageHeader.page_header id="h">
  <:title>Only</:title>
</PageHeader.page_header>|)

      assert html =~ "Only"
      refute html =~ "<p"
    end
  end

  describe "Sidebar" do
    defp sidebar(collapsed, toggle \\ "toggle") do
      assigns = %{collapsed: collapsed, toggle: toggle}

      rendered_to_string(~H"""
      <Sidebar.sidebar
        id="nav"
        label="Main"
        collapsed={@collapsed}
        on_toggle={@toggle}
        toggle_label="Collapse"
      >
        <:header>BRAND</:header>
        <:footer>FOOT</:footer>
        <:toggle_icon>T</:toggle_icon>
        <:icon :let={item}>I-{item.label}</:icon>
        <:item to="/a" label="Today" current />
        <:item to="/b" label="Review" count="3" />
      </Sidebar.sidebar>
      """)
    end

    test "open: the names are drawn, the current item is announced and the counts show" do
      html = sidebar(false)

      assert html =~ ~s(aria-label="Main")
      assert html =~ ~s(data-collapsed="false")
      assert html =~ ~s(aria-current="page")
      assert html =~ "Today" and html =~ "Review"
      assert html =~ ~r/>\s*3\s*</
      assert html =~ "BRAND" and html =~ "FOOT"
      assert html =~ ~s(aria-expanded="true")
      refute html =~ ~s(role="tooltip")
    end

    test "collapsed: only the icons, the names in tooltips and as accessible names" do
      html = sidebar(true)

      assert html =~ ~s(data-collapsed="true")
      assert length(Regex.scan(~r/role="tooltip"/, html)) == 2
      assert html =~ ~s(aria-labelledby="nav-tip-0")
      assert html =~ ~s(id="nav-tip-0")
      refute html =~ ~s(aria-label="Today")
      assert html =~ "group-hover/tip:opacity-100"
      assert html =~ "group-focus-within/tip:opacity-100"
      assert html =~ ~s(aria-expanded="false")
      refute html =~ ~r/>\s*3\s*</
    end

    test "the count takes the tone of its item, the quiet one without" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" label="Main" responsive={false}>
          <:icon>I</:icon>
          <:item to="/a" label="A" count="3" tone={:risk} />
          <:item to="/b" label="B" count="9" />
        </Sidebar.sidebar>
        """)

      assert html =~ "bg-tag-risk-bg"
      assert html =~ "text-tag-risk-text"
      assert html =~ "bg-wrap text-muted"
      assert html =~ ~s(data-responsive="false")
      assert sidebar(false) =~ ~s(data-responsive="true")
    end

    test "a toggle without a label is a mistake" do
      assigns = %{}

      assert_raise ArgumentError, ~r/toggle_label/, fn ->
        rendered_to_string(~H"""
        <Sidebar.sidebar id="nav" label="Main" on_toggle="t">
          <:item to="/a" label="A" />
        </Sidebar.sidebar>
        """)
      end
    end

    test "has no toggle when nobody listens" do
      refute sidebar(false, nil) =~ "nav-toggle"
    end
  end

  describe "CommandPalette" do
    defp palette(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            query: "ec",
            groups: [
              %{
                label: "Lessons",
                items: [%{id: "l1", label: "Ecto.Multi", to: "/l/1", hint: "30", tone: :warn}]
              }
            ],
            ask: "Ask the AI",
            scopes: [%{value: "all", label: "All"}, %{value: "prs", label: "PRs"}],
            ask_kbd: nil,
            close_key: "Esc",
            debounce: 150
          },
          extra
        )

      rendered_to_string(~H"""
      <CommandPalette.palette
        id="p"
        label="Search"
        query={@query}
        search_event="search"
        close_event="close"
        groups={@groups}
        empty="Nothing."
        ask_label={@ask}
        ask_event="ask"
        scopes={@scopes}
        scope="all"
        scope_event="scope"
        keys={[{"↑↓", "move"}, {"↵", "open"}]}
        ask_kbd={@ask_kbd}
        close_key={@close_key}
        debounce={@debounce}
      >
        <:search_icon>S</:search_icon>
        <:item_icon :let={item}>I-{item.label}</:item_icon>
      </CommandPalette.palette>
      """)
    end

    test "is a dialog with a field, the groups, the hint of each row and the keys" do
      html = palette()

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(phx-hook="DevactionUI.Autocomplete")
      assert length(Regex.scan(~r/phx-hook=/, html)) == 3
      assert html =~ ~s(phx-hook="DevactionUI.Segmented")
      assert html =~ ~s(role="combobox")
      assert html =~ ~s(role="listbox")
      assert html =~ "Lessons"
      assert html =~ "<strong"
      assert html =~ ~r/>\s*30\s*</
      assert html =~ "cmdk-footer"
      assert html =~ "move"
      assert html =~ ~s(phx-key="escape")
    end

    test "has the scopes and the ask-the-AI row with what was typed, or neither" do
      html = palette()

      assert html =~ ~s(role="group")
      assert html =~ ~s(phx-click="scope")
      assert html =~ ~s(phx-click="ask")
      assert html =~ ~s(phx-value-q="ec")
      assert html =~ "data-ask"

      bare = palette(%{scopes: [], ask: nil, groups: []})
      refute bare =~ ~s(phx-click="scope")
      refute bare =~ "data-ask"
      assert bare =~ "Nothing."
    end

    test "each group is a named role=group and the rows start unselected" do
      html = palette()

      assert html =~ ~s(role="group" aria-labelledby="p-group-0")
      assert html =~ ~s(id="p-group-0")
      assert html =~ ~s(aria-selected="false")
      assert File.read!("assets/css/devaction_ui.css") =~ ~r/\.cmdk\s+\{[^}]*shadow-cmdk/
      assert html =~ "max-h-[420px]"
    end

    test "aria-expanded follows the list: false with no row at all" do
      assert palette() =~ ~s(aria-expanded="true")

      bare = palette(%{ask: nil, groups: []})
      assert bare =~ ~s(aria-expanded="false")
      assert bare =~ ~r/class="m-0 px-2.5 py-7 text-center[^"]*"[^>]*>\s*Nothing\./
    end

    test "a row can send an event, patch or go to an href, with a second line, a shortcut and an icon" do
      html =
        palette(%{
          groups: [
            %{
              label: "Commands",
              items: [
                %{
                  id: "c1",
                  label: "Create contract",
                  event: "create",
                  sub: "In this project",
                  shortcut: "G C"
                },
                %{id: "c2", label: "Settings", patch: "/settings"},
                %{id: "c3", label: "Docs", href: "https://example.com"}
              ]
            }
          ]
        })

      assert html =~ ~s(phx-click="create")
      assert html =~ ~s(phx-value-id="c1")
      assert html =~ "In this project"
      assert html =~ "G C"
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="https://example.com")
      assert html =~ "I-Create contract"
    end

    test "the field has the Esc key cap, the key of the AI row and the debounce the caller sets" do
      html = palette()
      assert html =~ ~r/<kbd[^>]*>\s*Esc\s*<\/kbd>/
      assert html =~ ~s(phx-debounce="150")
      refute html =~ "⌘↵"

      assert palette(%{ask_kbd: "Ctrl ↵", close_key: nil, debounce: 300}) =~ "Ctrl ↵"
    end
  end
end
