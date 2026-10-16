defmodule DevactionUI.EditorSuggestTest do
  @moduledoc "The popup of the @ and / menus as a component: its listbox, its group label, its rows and the active one."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Editor

  defp people(extra \\ %{}) do
    assigns = Map.merge(%{active: 0, heading: "PEOPLE"}, extra)

    rendered_to_string(~H"""
    <Editor.suggest id="mentions" label="People" heading={@heading} active={@active}>
      <:option title="Alex" hint="Dev · online now">AN</:option>
      <:option title="Carlos André" hint="Dev · SGE" tone={:info}>CA</:option>
      <:option title="DevAction Reviewer" hint="AI · answers on the PR" tone={:warn}>AI</:option>
    </Editor.suggest>
    """)
  end

  test "is a labelled listbox with the group label and one option per row" do
    html = people()

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-label="People")
    assert html =~ "PEOPLE"
    assert length(Regex.scan(~r/role="option"/, html)) == 3
    assert html =~ ~s(id="mentions-option-2")
  end

  test "a row has a mark, a title and a hint" do
    html = people()

    assert html =~ "AN"
    assert html =~ "Alex"
    assert html =~ "Dev · online now"
    assert html =~ "Carlos André"
  end

  test "only the active row is selected and carries the Enter key cap" do
    html = people(%{active: 1})

    assert html =~ ~r/id="mentions-option-1"[^>]*aria-selected="true"/s
    assert html =~ ~r/id="mentions-option-0"[^>]*aria-selected="false"/s
    assert length(Regex.scan(~r/<kbd/, html)) == 1
    assert html =~ "↵"
  end

  test "with no active row none is selected and there is no key cap" do
    html = people(%{active: -1})

    refute html =~ ~s(aria-selected="true")
    refute html =~ "<kbd"
  end

  test "the mark is ink by default and takes a tone's colours" do
    html = people()

    assert html =~ "bg-ink text-on-primary"
    assert html =~ "bg-tag-info-bg"
    assert html =~ "text-tag-warn-text"
  end

  test "the group label is left out when there is none" do
    refute people(%{heading: nil}) =~ "PEOPLE"
  end

  test "a row with an event sends it with its value to the target" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Editor.suggest id="cmds" label="Commands" target="#editor">
        <:option title="/task" hint="Create a task" event="pick" value="task">T</:option>
      </Editor.suggest>
      """)

    assert html =~ ~s(phx-click="pick")
    assert html =~ ~s(phx-value-choice="task")
    assert html =~ ~s(phx-target="#editor")
  end

  test "takes the caller's own attributes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Editor.suggest id="x" label="x" data-mode="slash">
        <:option title="a">A</:option>
      </Editor.suggest>
      """)

    assert html =~ ~s(data-mode="slash")
  end
end
