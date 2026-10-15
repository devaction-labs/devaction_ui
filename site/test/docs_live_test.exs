defmodule DevactionUISite.DocsLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Catalog, ScreenHTML, Templates, TopicHTML}

  @endpoint DevactionUISite.Endpoint

  test "the overview links every topic" do
    {:ok, view, _html} = live(build_conn(), "/")

    assert has_element?(view, "#introduction")
    assert has_element?(view, "#principles")
    assert has_element?(view, "#components")

    for topic <- Catalog.all() do
      assert has_element?(view, "#card-#{topic.slug}")
    end
  end

  test "the installation page shows the three edits" do
    {:ok, view, _html} = live(build_conn(), "/installation")

    assert has_element?(view, "#installation")
    assert has_element?(view, "#css")
    assert has_element?(view, "#js")
    assert has_element?(view, "#use")
  end

  test "the tokens page lists the tokens read from the stylesheet" do
    {:ok, view, _html} = live(build_conn(), "/tokens")

    assert has_element?(view, "#tokens")
    assert has_element?(view, "#token-card")
    assert has_element?(view, "#token-tag-risk-bg")
  end

  for topic <- Catalog.all() do
    test "#{topic.slug} renders its examples with their source and the API of every module" do
      topic = Catalog.fetch(unquote(topic.slug)) |> elem(1)
      {:ok, view, _html} = live(build_conn(), "/c/#{topic.slug}")

      assert has_element?(view, "#topic-#{topic.slug}")
      assert has_element?(view, "#api")

      for example <- TopicHTML.for_topic(topic.slug) do
        assert has_element?(view, "#example-#{example.id}")
      end

      for module <- topic.modules do
        short = module |> Module.split() |> List.last()
        assert has_element?(view, "#api-#{short}")
      end
    end
  end

  test "the attribute table lists what a component accepts, with its allowed values" do
    {:ok, view, _html} = live(build_conn(), "/c/tag")

    assert has_element?(view, "#fn-tag-tag")
    assert has_element?(view, "#fn-tag-tag th", "variant")
    assert has_element?(view, "#fn-tag-tag td span", ":risk")
  end

  test "searching narrows the sidebar and enter opens the first match" do
    {:ok, view, _html} = live(build_conn(), "/")

    view |> form("#search-form", %{q: "kanban"}) |> render_change()
    assert has_element?(view, "#sidebar a[href='/c/kanban']")
    refute has_element?(view, "#sidebar a[href='/c/tag']")

    view |> form("#search-form", %{q: "kanban"}) |> render_submit()
    assert_patch(view, "/c/kanban")
  end

  test "a search with no match says so" do
    {:ok, view, _html} = live(build_conn(), "/")

    view |> form("#search-form", %{q: "zzzz"}) |> render_change()

    assert has_element?(view, "#sidebar [data-role=no-results]")
  end

  test "moving between pages is a patch, so the page stays alive" do
    {:ok, view, _html} = live(build_conn(), "/")

    view |> element("#card-tag") |> render_click()

    assert_patch(view, "/c/tag")
    assert has_element?(view, "#topic-tag")
    assert has_element?(view, "#pager-next")
  end

  test "an unknown topic goes back to the overview" do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(build_conn(), "/c/nope")
  end

  test "the address of the old catalog goes to the introduction" do
    conn = get(build_conn(), "/dev/ui?page=6")

    assert redirected_to(conn, 301) == "/"
  end

  describe "templates" do
    test "the auth page shows every screen in a frame that points at the real page, with its source" do
      {:ok, view, _html} = live(build_conn(), "/templates/auth")

      assert has_element?(view, "#templates-auth")

      for screen <- Templates.fetch("auth") |> elem(1) |> Map.fetch!(:screens),
          ScreenHTML.source("auth", screen.slug) do
        assert has_element?(view, "#screen-#{screen.slug}")

        assert has_element?(
                 view,
                 "#frame-auth-#{screen.slug} iframe[src='/screens/auth/#{screen.slug}']"
               )

        assert has_element?(view, "#template-auth-#{screen.slug}")
      end
    end

    test "the sidebar lists the template groups and moving to one is a patch" do
      {:ok, view, _html} = live(build_conn(), "/")

      view |> element("#sidebar a[href='/templates/auth']") |> render_click()

      assert_patch(view, "/templates/auth")
      assert has_element?(view, "#templates-auth")
    end

    test "an unknown group goes back to the introduction" do
      assert {:error, {:live_redirect, %{to: "/"}}} = live(build_conn(), "/templates/nope")
    end

    for screen <- Templates.fetch("auth") |> elem(1) |> Map.fetch!(:screens),
        ScreenHTML.source("auth", screen.slug) do
      test "the auth screen #{screen.slug} renders as a page of its own, with no documentation around it" do
        {:ok, view, html} = live(build_conn(), "/screens/auth/#{unquote(screen.slug)}")

        refute has_element?(view, "#sidebar")
        refute has_element?(view, "#topbar")
        assert html =~ "auth" or html =~ "id="
      end
    end

    test "an unknown screen goes back to the introduction" do
      assert {:error, {:redirect, %{to: "/"}}} = live(build_conn(), "/screens/auth/nope")
    end
  end
end
