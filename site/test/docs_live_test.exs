defmodule DevactionUISite.DocsLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{
    Catalog,
    Changelog,
    Project,
    Reference,
    Repo,
    ScreenHTML,
    Templates,
    TopicHTML
  }

  @endpoint DevactionUISite.Endpoint

  test "the introduction links every topic" do
    {:ok, view, _html} = live(build_conn(), "/docs")

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
    assert has_element?(view, "#fn-tag-tag td", ":risk")
  end

  test "searching narrows the sidebar and enter opens the first match" do
    {:ok, view, _html} = live(build_conn(), "/docs")

    view |> form("#search-form", %{q: "kanban"}) |> render_change()
    assert has_element?(view, "#sidebar a[href='/c/kanban']")
    refute has_element?(view, "#sidebar a[href='/c/tag']")

    view |> form("#search-form", %{q: "kanban"}) |> render_submit()
    assert_patch(view, "/c/kanban")
  end

  test "a search with no match says so" do
    {:ok, view, _html} = live(build_conn(), "/docs")

    view |> form("#search-form", %{q: "zzzz"}) |> render_change()

    assert has_element?(view, "#sidebar [data-role=no-results]")
  end

  test "moving between pages is a patch, so the page stays alive" do
    {:ok, view, _html} = live(build_conn(), "/docs")

    view |> element("#card-tag") |> render_click()

    assert_patch(view, "/c/tag")
    assert has_element?(view, "#topic-tag")
    assert has_element?(view, "#pager-next")
  end

  test "an unknown topic goes back to the introduction" do
    assert {:error, {:live_redirect, %{to: "/docs"}}} = live(build_conn(), "/c/nope")
  end

  test "the address of the old catalog goes to the home" do
    conn = get(build_conn(), "/dev/ui?page=6")

    assert redirected_to(conn, 301) == "/"
  end

  test "the document loads its styles and scripts through the endpoint's static paths" do
    html = html_response(get(build_conn(), "/docs"), 200)

    for path <- [
          "/assets/css/site.css",
          "/assets/js/app.js",
          "/assets/js/theme.js",
          "/images/favicon.svg"
        ] do
      assert html =~ DevactionUISite.Endpoint.static_path(path)
    end
  end

  describe "the shell" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Changelog.sync!()
      :ok
    end

    test "the home and the changelog have the header and no sidebar" do
      for path <- ["/", "/changelog"] do
        {:ok, view, _html} = live(build_conn(), path)

        assert has_element?(view, "#topbar")
        assert has_element?(view, "#topbar nav[aria-label=Main] a[href='/docs']", "Documentation")

        assert has_element?(
                 view,
                 "#topbar nav[aria-label=Main] a[href='/changelog']",
                 "Changelog"
               )

        refute has_element?(view, "#sidebar")
      end
    end

    test "the home header has the search, GitHub and the theme toggle" do
      {:ok, view, _html} = live(build_conn(), "/")

      assert has_element?(
               view,
               "#topbar[data-variant=home] input[placeholder='Search components']"
             )

      assert has_element?(view, "#topbar a[aria-label='DevAction UI on GitHub']")
      assert has_element?(view, "#theme-toggle")
      assert has_element?(view, "#topbar nav[aria-label=Main] a[href^='/c/']", "Components")
    end

    test "the changelog header has the Releases and RSS buttons instead of the search" do
      {:ok, view, _html} = live(build_conn(), "/changelog")

      assert has_element?(
               view,
               "#topbar[data-variant=changelog] a[href$='/releases']",
               "Releases"
             )

      assert has_element?(view, "#topbar a[href$='/releases.atom']", "RSS")
      refute has_element?(view, "#topbar input[type=search]")
      refute has_element?(view, "#theme-toggle")
    end

    test "the header shows the version of the package" do
      {:ok, view, _html} = live(build_conn(), "/docs")

      assert has_element?(view, "#topbar", "v#{Project.short_version()}")
      assert Project.version() =~ ~r/\A\d+\.\d+\.\d+/
    end

    test "the sidebar has the guides with the count of every group" do
      {:ok, view, _html} = live(build_conn(), "/docs")

      for {group, topics} <- Catalog.groups() do
        assert has_element?(view, "#sidebar h2", group)
        assert has_element?(view, "#sidebar h2 span", "#{length(topics)}")
      end

      assert has_element?(view, "#sidebar a[href='/docs'][aria-current=page]", "Introduction")
      assert has_element?(view, "#sidebar a[href='/changelog']", "Changelog")
      assert has_element?(view, "#sidebar a[href='/tokens']", "Colors and tokens")
    end

    test "the search without a sidebar lists the matches under the field" do
      {:ok, view, _html} = live(build_conn(), "/")

      view |> form("#search-form", %{q: "kanban"}) |> render_change()

      assert has_element?(view, "#search-results a[href='/c/kanban']")
      refute has_element?(view, "#search-results a[href='/c/tag']")
    end

    test "the introduction counts the components from the catalog" do
      {:ok, view, _html} = live(build_conn(), "/docs")

      count = Catalog.all() |> Enum.flat_map(& &1.modules) |> length()
      assert has_element?(view, "#introduction", "#{count} function components")
    end
  end

  describe "a component page" do
    test "a component added in v0.2 says so" do
      {:ok, view, _html} = live(build_conn(), "/c/file_tree")

      assert has_element?(view, "#topic-file_tree", "since v0.2")
      assert Catalog.since("FileTree") == "0.2"
      assert Catalog.since("Button") == "0.1"
    end

    test "has the breadcrumb, the status, the links and the history of the component" do
      {:ok, view, _html} = live(build_conn(), "/c/button")

      assert has_element?(view, "nav[aria-label=Breadcrumb] li[aria-current=page]", "Button")
      assert has_element?(view, "#topic-button h1", "Button")
      assert has_element?(view, "#topic-button", "Stable")
      assert has_element?(view, "#topic-button", "since v0.1")
      assert has_element?(view, "#topic-button [data-copy-text='alias DevactionUI.Button']")

      assert has_element?(
               view,
               "#topic-button a[href='#{Project.repo_url()}/blob/main/lib/devaction_ui/button.ex']",
               "Source code"
             )

      assert has_element?(view, "#topic-button a[href='/changelog']", "History")
      assert has_element?(view, "aside a[href='/changelog']", "See in the changelog")
      assert has_element?(view, "aside a[href='#{Project.issues_url()}']")
    end

    test "every example has the preview and HEEx tabs, the theme switch and the copy button" do
      {:ok, view, _html} = live(build_conn(), "/c/button")

      for example <- TopicHTML.for_topic("button") do
        id = "example-#{example.id}"
        assert has_element?(view, "##{id} [role=tab][aria-selected=true]", "Preview")
        assert has_element?(view, "##{id} [role=tab][aria-selected=false]", "HEEx")
        assert has_element?(view, "##{id} button[aria-pressed=false]", "Light")
        assert has_element?(view, "##{id} [data-copy-text]")
        assert has_element?(view, "##{id} #pv-#{id}[data-flip=false]")
      end
    end

    test "the index on the right lists the examples and the API" do
      {:ok, view, _html} = live(build_conn(), "/c/button")

      assert has_element?(view, "nav[aria-label='On this page'] a[href='#api']")

      for example <- TopicHTML.for_topic("button") do
        assert has_element?(view, "nav[aria-label='On this page'] a[href='##{example.id}']")
      end
    end

    test "the pager goes to the neighbours" do
      {:ok, view, _html} = live(build_conn(), "/c/button")
      {previous, next} = Catalog.neighbours(%{slug: "button"})

      assert has_element?(view, "#pager-previous[href='/c/#{previous.slug}']")
      assert has_element?(view, "#pager-next[href='/c/#{next.slug}']")
    end

    for topic <- Catalog.all() do
      test "#{topic.slug} points to the file of its module" do
        {:ok, topic} = Catalog.fetch(unquote(topic.slug))
        file = Project.source_url(topic.module) |> String.split("/blob/main/") |> List.last()

        assert File.exists?(Path.expand("../../" <> file, __DIR__))
      end
    end

    test "the accessibility notes come from the section of the moduledoc" do
      assert Reference.accessibility(DevactionUI.Button) == []

      doc = "Intro.\n\n## Accessibility\n\n- One note.\n* Two `notes`.\n\n## Other\n\n- Not this."

      assert Reference.accessibility_notes(doc) == ["One note.", "Two `notes`."]
      assert Reference.accessibility_notes("No section here.") == []
    end
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
      {:ok, view, _html} = live(build_conn(), "/docs")

      view |> element("#sidebar a[href='/templates/auth']") |> render_click()

      assert_patch(view, "/templates/auth")
      assert has_element?(view, "#templates-auth")
    end

    test "an unknown group goes back to the introduction" do
      assert {:error, {:live_redirect, %{to: "/docs"}}} = live(build_conn(), "/templates/nope")
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
