defmodule DevactionUISite.NewBadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.Catalog

  @endpoint DevactionUISite.Endpoint

  test "only the components that came with the shown version are new" do
    assert Catalog.new?("Listbox")
    refute Catalog.new?("Select")
    refute Catalog.new?("Accordion")
    refute Catalog.new?("Email")
  end

  test "the sidebar, the cards and the page title say New for a new component" do
    {:ok, view, _html} = live(build_conn(), "/c/listbox")

    assert has_element?(view, "nav a[href='/c/listbox']", "New")
    refute has_element?(view, "nav a[href='/c/accordion']", "New")
    assert has_element?(view, "h1 ~ *", "New")

    {:ok, view, _html} = live(build_conn(), "/docs")
    assert has_element?(view, "#card-listbox", "New")
    refute has_element?(view, "#card-accordion", "New")
  end
end
