defmodule DevactionUISite.ListboxExampleTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint DevactionUISite.Endpoint

  defp example(id) do
    {:ok, view, _html} = live(build_conn(), "/preview/listbox")
    find_live_child(view, "live-preview-" <> id)
  end

  test "creating from the search adds the option and chooses it" do
    child = example("listbox-03")

    refute has_element?(child, "[data-value=design]")

    render_hook(child, "create_tag", %{"id" => "listbox-create", "term" => "Design"})

    assert has_element?(child, "[data-value=design][aria-selected=true]")
    assert has_element?(child, "input[type=hidden][name=tag][value=design]")
    assert has_element?(child, "[data-current]", "Design")
    assert has_element?(child, ".listbox-hint", "Enter")
  end

  test "a choice that reaches the form is the one the server sees" do
    child = example("listbox-05")

    assert has_element?(child, "#ticket-params", "\"team\" => \"api\"")

    render_hook(child, "ticket_change", %{
      "ticket" => %{"team" => "web", "labels" => ["", "bug", "chore"]}
    })

    assert has_element?(child, "#ticket-params", "\"team\" => \"web\"")
    assert has_element?(child, "#ticket-form_team [data-value=web][aria-selected=true]")
    assert has_element?(child, "#ticket-form_labels [data-current]", "2 labels")
  end

  test "the search example offers the clear button and a disabled row" do
    child = example("listbox-01")

    assert has_element?(child, "#listbox-search [data-search-clear][aria-label='Clear search']")
    assert has_element?(child, "#listbox-search [data-value=hr][aria-disabled=true]")
  end
end
