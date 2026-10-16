defmodule DevactionUISite.AppTemplateTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Repo, ScreenHTML}

  @endpoint DevactionUISite.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "the App page shows the projects screen in a frame that points at the real page" do
    {:ok, view, _html} = live(build_conn(), "/templates/app")

    assert has_element?(view, "#templates-app")
    assert has_element?(view, "#frame-app-projects iframe[src='/screens/app/projects']")
    assert has_element?(view, "#template-app-projects")
    assert ScreenHTML.source("app", "projects") =~ "Shell.shell"
  end

  test "the projects screen draws the shell, the page head and the table" do
    {:ok, view, _html} = live(build_conn(), "/screens/app/projects")

    assert has_element?(view, "#app-shell .shell-sidebar", "DevAction Labs")
    assert has_element?(view, "#app-shell .sidebar-user", "alex@devaction.com.br")
    assert has_element?(view, "#app-projects-head h1", "Projects")
    assert has_element?(view, "#app-projects-tabs [role=tab]", "Findings")
    assert has_element?(view, "#app-projects-table th", "Owner")
    assert has_element?(view, "#app-projects-table td", "Carlos André")
    assert has_element?(view, "#app-projects-table td", "12 min ago")
    assert has_element?(view, "#app-projects-table td[data-actions]")
    refute has_element?(view, "#app-projects-table th", "Milestone")
    refute has_element?(view, "#app-projects-table th[data-sticky]")
    assert has_element?(view, "#app-projects-table [role=progressbar]")
    assert has_element?(view, "#app-row-menu-sge", "Review with AI")
    assert has_element?(view, "#app-projects-head", "8 of 8")
  end

  test "the risk filter narrows the table and the count" do
    {:ok, view, _html} = live(build_conn(), "/screens/app/projects")

    view |> element("#app-projects-risk-high") |> render_click()

    assert has_element?(view, "#app-projects-head", "2 of 8")
    assert has_element?(view, "#app-projects-table", "SGE")
    refute has_element?(view, "#app-projects-table", "Hub API")
  end

  test "sorting by risk goes descending, ascending and back to none" do
    {:ok, view, _html} = live(build_conn(), "/screens/app/projects")

    sort = fn -> view |> element("#app-projects-table th button", "Risk") |> render_click() end

    assert sort.() =~ ~s(aria-sort="descending")
    assert sort.() =~ ~s(aria-sort="ascending")
    assert sort.() =~ ~s(aria-sort="none")
  end

  test "the new example of the DataTable page is listed" do
    {:ok, view, _html} = live(build_conn(), "/c/data_table")

    assert has_element?(view, "#topic-data_table", "Progress cells and a row menu")

    for title <- [
          "Minimal, compact and striped",
          "Expandable rows",
          "Grouped rows and totals",
          "Cards on the phone",
          "Row menu in the action slot",
          "Footer with pagination"
        ] do
      assert has_element?(view, "#topic-data_table", title)
    end
  end
end
