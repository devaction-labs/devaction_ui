defmodule DevactionUISite.HomeChangelogTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias DevactionUISite.{Catalog, Changelog, Repo, Templates}

  @endpoint DevactionUISite.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Changelog.sync!()
  end

  describe "home" do
    test "renders the hero, the numbers, the showcase, the catalog and the footer" do
      {:ok, view, html} = live(build_conn(), "/")
      count = length(Catalog.all())

      assert has_element?(view, "#home h1", "The interface of all")
      assert html =~ "#{count} components published"
      assert has_element?(view, "#numbers", "#{count}")
      assert has_element?(view, "#numbers", "UI dependencies")

      assert has_element?(
               view,
               "#catalog h2",
               "#{count} components in #{length(Catalog.groups()) + length(Templates.groups())} groups"
             )

      assert has_element?(view, "#latest a[href='/changelog']", "See full changelog")
      assert has_element?(view, "footer", "made by DevAction Labs")
    end

    test "the buttons go to the installation and to the first component" do
      {:ok, view, _html} = live(build_conn(), "/")

      assert has_element?(view, "#hero a[href='/installation']", "Get started")
      assert has_element?(view, "#hero a[href='/c/#{hd(Catalog.all()).slug}']")
    end

    test "the install card has one tab and one panel per file with the true snippets" do
      {:ok, view, html} = live(build_conn(), "/")

      for tab <- ~w(mix css js) do
        assert has_element?(view, "#install-tab-#{tab}[role=tab]")
        assert has_element?(view, "#install-panel-#{tab}[role=tabpanel]")
      end

      assert html =~ ~s|{:devaction_ui, &quot;~&gt; 0.3.0&quot;}|
      assert html =~ "@import &quot;../../deps/devaction_ui/assets/css/devaction_ui.css&quot;;"
      assert html =~ "hooks as devactionUI"
    end

    test "the seven showcase cards link to their component pages" do
      {:ok, view, _html} = live(build_conn(), "/")

      for slug <- ~w(button command_palette switch tag chart data_table ai_prompt) do
        assert has_element?(view, "#show-#{slug} a[href='/c/#{slug}']")
      end
    end

    test "the catalog lists every component and the templates" do
      {:ok, view, _html} = live(build_conn(), "/")

      for topic <- Catalog.all() do
        assert has_element?(view, "#catalog a[href='/c/#{topic.slug}']")
      end

      for group <- Templates.groups() do
        assert has_element?(view, "#catalog a[href='/templates/#{group.slug}']")
      end
    end

    test "the four principles are there" do
      {:ok, view, _html} = live(build_conn(), "/")

      for title <- [
            "Tokens, not colors",
            "Keyboard first",
            "State on the server",
            "No built-in text"
          ] do
        assert has_element?(view, "#principles h3", title)
      end
    end
  end

  describe "changelog" do
    test "renders the header, the filters with their counts and every version" do
      {:ok, view, _html} = live(build_conn(), "/changelog")
      counts = Changelog.counts(Changelog.versions())

      assert has_element?(view, "#changelog h1", "What changed in DevAction UI")
      assert has_element?(view, "[data-filter=all]", "#{counts["all"]}")
      assert has_element?(view, "[data-filter=planned]", "1")
      assert has_element?(view, "[data-filter=breaking]", "#{counts["breaking"]}")
      assert has_element?(view, "#v04[data-release]", "no date")
      assert has_element?(view, "#v030[data-release]", "tag v0.3.0")
      assert has_element?(view, "#v026[data-release]", "tag v0.2.6")
      assert has_element?(view, "#v025[data-release]", "tag v0.2.5")
      assert has_element?(view, "#v024[data-release]", "tag v0.2.4")
      assert has_element?(view, "#v023[data-release]", "tag v0.2.3")
      assert has_element?(view, "#v022[data-release]", "tag v0.2.2")
      assert has_element?(view, "#v021[data-release]", "tag v0.2.1")
      assert has_element?(view, "#v020[data-release]", "tag v0.2.0")
      assert has_element?(view, "#v010[data-release]", "tag v0.1.0")
    end

    test "the current version has the install line, and v0.2.0 a table per group listing what is new" do
      {:ok, view, html} = live(build_conn(), "/changelog")

      assert html =~ "{:devaction_ui, &quot;~&gt; 0.3.0&quot;}"
      assert has_element?(view, "#v032 [data-copy-text*='~> 0.3.0']")

      for group <- ~w(Base Overlay Form Data) do
        assert has_element?(view, "#v020-#{String.downcase(group)}[data-group]", group)
      end

      for topic <- Catalog.all(), Catalog.since(topic) == "0.2" do
        assert has_element?(view, "#v020 li[data-kind=new] a[href='/c/#{topic.slug}']")
      end

      assert has_element?(view, "#v020 li[data-kind=breaking]", "confirm_dialog")
      assert has_element?(view, "#v020 li[data-kind=improved]", "toast_group")
      assert has_element?(view, "#v023 li[data-kind=breaking]", "toast_group")
      assert has_element?(view, "#v021 li[data-kind=fixed]", "site_assets")
    end

    test "v0.1.0 lists the components it came with" do
      {:ok, view, _html} = live(build_conn(), "/changelog")

      for topic <- Catalog.all(), Catalog.since(topic) == "0.1" do
        assert has_element?(view, "#v010 li[data-kind=new] a[href='/c/#{topic.slug}']")
      end
    end

    test "only what is truly missing is planned for v0.3" do
      {:ok, view, _html} = live(build_conn(), "/changelog")

      assert has_element?(view, "#v04 li[data-kind=planned]", "x-ui.*")

      for name <- ~w(file_tree pdf_viewer otp_input date_range dropzone) do
        refute has_element?(view, "#v04 li", name)
      end
    end

    test "the summary of an entry is the first sentence of the moduledoc" do
      {:ok, view, _html} = live(build_conn(), "/changelog")
      {:ok, tabs} = Catalog.fetch("tabs")

      assert has_element?(view, "#v010-base li", Catalog.summary(tabs))
    end
  end
end
