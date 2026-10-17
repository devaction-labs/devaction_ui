defmodule DevactionUISite.NewBadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Catalog, Project}

  @endpoint DevactionUISite.Endpoint

  test "a component is new when it came with the version the site shows" do
    for topic <- Catalog.all() do
      assert Catalog.new?(topic) == (Catalog.since(topic) == Project.short_version())
    end

    refute Catalog.new?("Accordion")
    refute Catalog.new?("Email")
  end

  test "the sidebar, the cards and the page title say New for exactly the new components" do
    {:ok, docs, _html} = live(build_conn(), "/docs")

    for topic <- Catalog.groups() |> Enum.flat_map(&elem(&1, 1)) do
      assert has_element?(docs, "#card-#{topic.slug}", "New") == Catalog.new?(topic)
    end

    {:ok, page, _html} = live(build_conn(), "/c/accordion")

    refute has_element?(page, "nav a[href='/c/accordion']", "New")
    refute has_element?(page, "h1 ~ *", "New")
  end

  test "the New tag is the same chip in the sidebar, the cards and the title" do
    html = render_component(&DevactionUISite.Shell.new_tag/1, %{class: "ml-auto"})

    assert html =~ "New"
    assert html =~ "ml-auto"
  end
end
