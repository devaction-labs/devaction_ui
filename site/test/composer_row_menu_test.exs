defmodule DevactionUISite.ComposerRowMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Catalog, ExampleLive}

  @endpoint DevactionUISite.Endpoint

  defp example(id) do
    {:ok, view, _html} =
      live_isolated(build_conn(), ExampleLive, session: %{"example" => id})

    view
  end

  test "the two components say they came in v0.3" do
    assert Catalog.since("Composer") == "0.3"
    assert Catalog.since("RowMenu") == "0.3"
    assert {:ok, %{category: "AI"}} = Catalog.fetch("composer")
    assert {:ok, %{category: "Overlay"}} = Catalog.fetch("row_menu")
  end

  test "the page of a v0.3 component says so" do
    {:ok, view, _html} = live(build_conn(), "/c/composer")

    assert has_element?(view, "#topic-composer", "since v0.3")
  end

  test "sending a message lists it and tells the composer to empty itself" do
    view = example("composer-01")

    view
    |> form("#composer-basic-form", %{prompt: "Review PR 214"})
    |> render_submit()

    assert render(view) =~ "Review PR 214"
    assert_push_event(view, "composer:clear", %{id: "composer-basic"})
  end

  test "an answer in progress turns send into stop, and stopping ends it" do
    view = example("composer-02")

    view |> form("#composer-stream-form", %{prompt: "Summarize"}) |> render_submit()

    assert has_element?(view, "#composer-stream[data-busy=true]")
    assert has_element?(view, "#composer-stream button[data-stop]")
    assert has_element?(view, "#composer-stream textarea[readonly]")

    render_hook(view, "composer_stop", %{})

    assert has_element?(view, "#composer-stream[data-busy=false]")
    refute has_element?(view, "#composer-stream button[data-stop]")
  end

  test "the files of the composer are an upload that accepts a dropped file" do
    view = example("composer-03")

    upload =
      file_input(view, "#composer-files-form", :attachments, [
        %{name: "plan.txt", content: "the plan", type: "text/plain"}
      ])

    render_upload(upload, "plan.txt")

    assert has_element?(view, "#composer-files .composer-file", "plan.txt")
    assert has_element?(view, "#composer-files button[aria-label='Remove plan.txt']")
  end

  test "the menu of a row is fixed and lists the row's actions" do
    view = example("row_menu-01")

    assert has_element?(view, "#row-menu-142[data-fixed=true]")
    assert has_element?(view, "#row-menu-142-menu[role=menu] button", "Rename")

    view |> element("#row-menu-142-menu button", "Rename") |> render_click()

    assert render(view) =~ "Chose: rename-142"
  end
end
