defmodule DevactionUISite.SelectExampleTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint DevactionUISite.Endpoint

  test "the groups example is the real select that opens the styled panel, not a drawing of it" do
    {:ok, view, html} = live(build_conn(), "/c/select")

    assert has_element?(view, "select#select-role[phx-hook='DevactionUI.Select']")
    assert has_element?(view, "select#select-role optgroup[label=Team]")
    assert has_element?(view, "select#select-role option[value=viewer][disabled]")
    refute html =~ "Open, with groups"
  end

  test "the select page shows the searchable list, through the Listbox" do
    {:ok, view, _html} = live(build_conn(), "/c/select")

    assert has_element?(view, "#select-search[phx-hook='DevactionUI.Listbox']")
    assert has_element?(view, "#select-search input[data-search][placeholder='Search...']")
  end
end
