defmodule DevactionUI.FileTreeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.FileTree

  @nodes [
    %{path: "lib", type: :dir},
    %{path: "lib/sge", type: :dir, depth: 1},
    %{
      path: "lib/sge/milestone.ex",
      type: :file,
      name: "milestone.ex",
      depth: 2,
      status: :modified,
      additions: 18,
      deletions: 6,
      findings: 2,
      level: :risk
    },
    %{
      path: "lib/sge/invoice.ex",
      type: :file,
      name: "invoice.ex",
      depth: 2,
      status: :added,
      additions: 64
    },
    %{path: "test", type: :dir},
    %{
      path: "test/old_test.exs",
      type: :file,
      depth: 1,
      status: :deleted,
      deletions: 48,
      findings: 1
    }
  ]

  defp paths(rows), do: Enum.map(rows, & &1.path)

  describe "visible/4" do
    test "shows the folders and only the files of open folders" do
      assert paths(FileTree.visible(@nodes, [], :all, "")) == ["lib", "test"]

      assert paths(FileTree.visible(@nodes, ["lib"], :all, "")) ==
               ["lib", "lib/sge", "test"]

      assert paths(FileTree.visible(@nodes, ["lib", "lib/sge", "test"], :all, "")) ==
               Enum.map(@nodes, & &1.path)
    end

    test "fills the defaults of a node" do
      assert [%{name: "lib/", depth: 0, findings: 0, additions: 0, level: :warn, status: nil} | _] =
               FileTree.visible(@nodes, [])

      assert %{name: "old_test.exs", depth: 1} =
               @nodes |> FileTree.visible(["test"]) |> List.last()
    end

    test "the findings filter keeps the files with findings and the folders that hold them" do
      assert paths(FileTree.visible(@nodes, ["lib", "lib/sge", "test"], :findings)) ==
               ["lib", "lib/sge", "lib/sge/milestone.ex", "test", "test/old_test.exs"]
    end

    test "the new filter keeps the added files" do
      assert paths(FileTree.visible(@nodes, ["lib", "lib/sge", "test"], :new)) ==
               ["lib", "lib/sge", "lib/sge/invoice.ex"]
    end

    test "a search text matches the path in any case and opens every folder" do
      assert paths(FileTree.visible(@nodes, [], :all, "MILE")) ==
               ["lib", "lib/sge", "lib/sge/milestone.ex"]

      assert FileTree.visible(@nodes, [], :all, "zzz") == []
    end

    test "a filter and a search work together" do
      assert paths(FileTree.visible(@nodes, [], :new, "sge")) ==
               ["lib", "lib/sge", "lib/sge/invoice.ex"]
    end

    test "a folder that is not a node does not hide its files" do
      nodes = [%{path: "priv/repo/m.exs", type: :file, depth: 0}]
      assert paths(FileTree.visible(nodes, [])) == ["priv/repo/m.exs"]
    end
  end

  test "totals sums the lines of the files only" do
    assert FileTree.totals(@nodes) == %{additions: 82, deletions: 54}
  end

  defp render_tree(extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          nodes: @nodes,
          open: ["lib", "lib/sge"],
          selected: "lib/sge/milestone.ex",
          filter: :all,
          query: ""
        },
        extra
      )

    rendered_to_string(~H"""
    <FileTree.tree
      id="tree"
      label="Changed files"
      title="Changed files"
      nodes={@nodes}
      open={@open}
      selected={@selected}
      filter={@filter}
      query={@query}
      search_label="Filter files"
      search_key="t"
      findings_label="%{count} findings"
    >
      <:pill id={:all} label="All" />
      <:pill id={:findings} label="With findings" />
      <:legend status={:added} label="new" />
      <:legend status={:modified} label="changed" />
      <:search_hint>T</:search_hint>
      <:empty>Nothing matches</:empty>
    </FileTree.tree>
    """)
  end

  test "is a tree of items with levels, the open state and the selection" do
    html = render_tree()

    assert html =~ ~s(role="tree")
    assert html =~ ~s(phx-hook="DevactionUI.FileTree")
    assert html =~ ~r/role="treeitem"[^>]*aria-level="1"[^>]*aria-expanded="true"/s
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-level="3")
    assert html =~ ~s(aria-expanded="false")
  end

  test "files are not expandable" do
    html = render_tree()
    [[file]] = Regex.scan(~r/<button[^>]*data-path="lib\/sge\/invoice.ex"[^>]*>/s, html)
    refute file =~ "aria-expanded"
  end

  test "only the selected item is in the Tab order" do
    html = render_tree()
    assert html =~ ~s(data-stop="lib/sge/milestone.ex")
    assert length(Regex.scan(~r/tabindex="0"/, html)) == 1
  end

  test "without a visible selection the first item is the stop" do
    assert render_tree(%{selected: "nope"}) =~ ~s(data-stop="lib")
  end

  test "folders send the toggle event and files the select event, with the path" do
    html = render_tree()
    assert html =~ ~r/phx-click="toggle_folder"[^>]*phx-value-path="lib"/s
    assert html =~ ~r/phx-click="select_file"[^>]*phx-value-path="lib\/sge\/milestone.ex"/s
  end

  test "the header counts the files and the lines" do
    html = render_tree()
    assert html =~ ~r/text-\[11px\] text-muted">\s*3\s*</
    assert html =~ "+82"
    assert html =~ "−54"
  end

  test "the findings badge and the status letter are drawn with their names" do
    html = render_tree()
    assert html =~ ~s(aria-label="2 findings")
    assert html =~ "bg-finding-risk"
    assert html =~ ~r/aria-label="changed"[^>]*>\s*M\s*</
    assert html =~ ~r/aria-label="new"[^>]*>\s*A\s*</
  end

  test "the legend footer lists the letters it was given and only exists with a legend" do
    assert render_tree() =~ "border-t border-line-soft"

    assigns = %{nodes: @nodes}

    bare =
      rendered_to_string(~H"""
      <FileTree.tree id="t" label="F" title="F" nodes={@nodes} search_label="S" />
      """)

    refute bare =~ "border-t border-line-soft"
  end

  test "filter pills say which one is pressed" do
    html = render_tree(%{filter: :findings})
    assert html =~ ~r/aria-pressed="false"[^>]*phx-value-filter="all"/s
    assert html =~ ~r/aria-pressed="true"[^>]*phx-value-filter="findings"/s
  end

  test "the search field carries the query, the hint and the shortcut for the hook" do
    html = render_tree(%{query: "mile"})
    assert html =~ ~s(value="mile")
    assert html =~ ~s(data-search-key="t")
    assert html =~ "data-tree-search"
    assert html =~ ~s(phx-change="search_files")
    assert html =~ "<kbd"
  end

  test "an empty result says so" do
    assert render_tree(%{query: "zzz"}) =~ "Nothing matches"
  end

  test "the events and the target come from the attributes" do
    assigns = %{nodes: @nodes}

    html =
      rendered_to_string(~H"""
      <FileTree.tree
        id="t"
        label="Files"
        title="Files"
        nodes={@nodes}
        search_label="Search"
        select_event="pick"
        toggle_event="fold"
        search_event="find"
        target="#owner"
      />
      """)

    assert html =~ ~s(phx-click="fold")
    assert html =~ ~s(phx-change="find")
    assert html =~ ~s(phx-target="#owner")
  end

  test "icons come from slots and the arrow falls back to a glyph" do
    assigns = %{nodes: @nodes}

    html =
      rendered_to_string(~H"""
      <FileTree.tree id="t" label="F" title="F" nodes={@nodes} open={["lib"]} search_label="S">
        <:folder_icon><i class="folder"></i></:folder_icon>
        <:file_icon><i class="file"></i></:file_icon>
      </FileTree.tree>
      """)

    assert html =~ ~s(class="folder")
    assert html =~ "›"
  end

  test "a chevron slot replaces the glyph" do
    assigns = %{nodes: @nodes}

    html =
      rendered_to_string(~H"""
      <FileTree.tree id="t" label="F" title="F" nodes={@nodes} search_label="S">
        <:chevron_icon><i class="chev"></i></:chevron_icon>
      </FileTree.tree>
      """)

    assert html =~ ~s(class="chev")
    refute html =~ "›"
  end

  test "the arrow turns only on an open folder" do
    html = render_tree(%{open: ["lib"]})
    assert length(Regex.scan(~r/rotate-90/, html)) == 1
  end
end
