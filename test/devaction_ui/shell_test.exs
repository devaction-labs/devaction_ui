defmodule DevactionUI.ShellTest do
  @moduledoc "The shell: the sidebar and its parts, the state kept in the cookie and the hook it needs."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Shell
  alias DevactionUI.Shell.SidebarCookie

  defp render_shell(extra \\ %{}) do
    assigns = Map.merge(%{open: true, variant: "classic", width: nil}, extra)

    rendered_to_string(~H"""
    <Shell.shell
      id="app"
      variant={@variant}
      sidebar_open={@open}
      content_width={@width}
      sidebar_label="Main"
      open_label="Open menu"
      close_label="Collapse menu"
      data-extra="x"
    >
      <:sidebar>
        <Shell.sidebar_head name="Acme" subtitle="Workspace">
          <:logo>LOGO</:logo>
        </Shell.sidebar_head>
        <Shell.sidebar_nav>
          <Shell.sidebar_group id="work" label="Work">
            <:icon>CHEV</:icon>
            <Shell.sidebar_item tip="Projects" navigate="/projects" current badge={6}>
              <:icon>ICON</:icon>
              Projects
              <:sub>
                <Shell.sidebar_item tip="Archived" navigate="/archived">Archived</Shell.sidebar_item>
              </:sub>
            </Shell.sidebar_item>
          </Shell.sidebar_group>
        </Shell.sidebar_nav>
        <Shell.sidebar_foot>FOOT</Shell.sidebar_foot>
      </:sidebar>
      <:header>HEADER</:header>
      <:header_actions>ACTIONS</:header_actions>
      <:list>LIST</:list>
      <:toc>TOC</:toc>
      <:toggle_icon>TOGGLE</:toggle_icon>
      PAGE
    </Shell.shell>
    """)
  end

  describe "shell" do
    test "is a hooked frame whose hook leaves its own attributes alone" do
      html = render_shell()

      assert html =~ ~s(id="app")
      assert html =~ ~s(phx-hook="DevactionUI.Shell")
      assert html =~ "data-sidebar"
      assert html =~ "data-mobile-open"
      assert html =~ ~s(data-extra="x")
      assert html =~ ~s(data-variant="classic")
    end

    test "renders the state the server was given: open or the rail" do
      assert render_shell() =~ ~s(data-sidebar="open")
      assert render_shell(%{open: false}) =~ ~s(data-sidebar="rail")
    end

    test "the toggle says what it does for the state it is in" do
      open = render_shell()
      assert open =~ ~s(aria-label="Collapse menu")
      assert open =~ ~s(aria-expanded="true")
      assert open =~ ~s(aria-controls="app-sidebar")
      assert open =~ ~s(aria-keyshortcuts="Meta+B Control+B")
      assert open =~ ~s(data-label-open="Open menu")
      assert open =~ ~s(data-label-close="Collapse menu")

      rail = render_shell(%{open: false})
      assert rail =~ ~s(aria-label="Open menu")
      assert rail =~ ~s(aria-expanded="false")
    end

    test "draws every slot and gives the toggle its icon" do
      html = render_shell()

      for part <- ~w(LOGO CHEV ICON FOOT HEADER ACTIONS LIST TOC TOGGLE PAGE),
          do: assert(html =~ part)

      assert html =~ ~s(aria-label="Main")
      assert html =~ "data-sidebar-backdrop"
    end

    test "the variant and the content width are data attributes" do
      html = render_shell(%{variant: "docs", width: "read"})

      assert html =~ ~s(data-variant="docs")
      assert html =~ ~s(data-width="read")
    end

    test "a shell with no sidebar has no toggle, no backdrop and needs no labels" do
      assigns = %{}

      html = rendered_to_string(~H|<Shell.shell id="bare">PAGE</Shell.shell>|)

      refute html =~ "data-sidebar-toggle"
      refute html =~ "data-sidebar-backdrop"
      assert html =~ "PAGE"
    end

    test "a sidebar without its texts raises" do
      assigns = %{}

      assert_raise ArgumentError, ~r/sidebar_label/, fn ->
        rendered_to_string(~H"""
        <Shell.shell id="a" open_label="o" close_label="c"><:sidebar>S</:sidebar>P</Shell.shell>
        """)
      end

      assert_raise ArgumentError, ~r/open_label/, fn ->
        rendered_to_string(~H"""
        <Shell.shell id="a" sidebar_label="s" close_label="c"><:sidebar>S</:sidebar>P</Shell.shell>
        """)
      end

      assert_raise ArgumentError, ~r/close_label/, fn ->
        rendered_to_string(~H"""
        <Shell.shell id="a" sidebar_label="s" open_label="o"><:sidebar>S</:sidebar>P</Shell.shell>
        """)
      end
    end
  end

  describe "sidebar parts" do
    test "the head shows the workspace, and the subtitle and the menu only when given" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Shell.sidebar_head name="Acme">
  <:logo>L</:logo>
</Shell.sidebar_head>|)

      assert html =~ "Acme"
      refute html =~ "sidebar-head-sub"
      refute html =~ "sidebar-head-menu"
    end

    test "an item is a link with its name for the rail, the current page and a badge" do
      html = render_shell()

      assert html =~ ~r/<a[^>]*href="\/projects"[^>]*aria-current="page"/s
      assert html =~ ~s(aria-label="Projects")
      assert html =~ ~s(data-tip="Projects")
      assert html =~ ~r/sidebar-item-badge[^>]*>\s*6/
      assert html =~ "sidebar-sub"
      refute html =~ ~r/<a[^>]*href="\/archived"[^>]*aria-current/s
    end

    test "an item marks the dot and the tone of its badge" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.sidebar_item tip="PRs" navigate="/prs" dot badge="2" badge_tone="ai">
          PRs
        </Shell.sidebar_item>
        """)

      assert html =~ "data-dot"
      assert html =~ ~s(data-tone="ai")
    end

    test "a group is a toggle and a body that start open or closed and keep what the person chose" do
      assigns = %{}

      closed =
        rendered_to_string(~H"""
        <Shell.sidebar_group id="team" label="Team" open={false}>ITEMS</Shell.sidebar_group>
        """)

      assert closed =~ ~s(data-sidebar-group="team")
      assert closed =~ ~s(aria-expanded="false")
      assert closed =~ ~s(aria-controls="team-group")
      assert closed =~ ~s(id="team-group")
      assert closed =~ ~s(data-collapsed="")
      assert closed =~ "data-group-body hidden"
      assert closed =~ "phx-mounted"
      assert closed =~ "▾"

      opened =
        rendered_to_string(
          ~H|<Shell.sidebar_group id="team" label="Team">ITEMS</Shell.sidebar_group>|
        )

      assert opened =~ ~s(aria-expanded="true")
      refute opened =~ ~r/\sdata-collapsed[\s>]/
      refute opened =~ "data-group-body hidden"
    end
  end

  describe "the state across requests" do
    test "only the rail cookie collapses the sidebar" do
      assert SidebarCookie.open?("open")
      assert SidebarCookie.open?(nil)
      assert SidebarCookie.open?("anything")
      refute SidebarCookie.open?("rail")
    end

    test "the plug copies the cookie into the session" do
      rail =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.put_req_cookie("dui_sidebar", "rail")
        |> init_session()
        |> SidebarCookie.call([])

      assert Plug.Conn.get_session(rail, "sidebar_open") == false

      none = Plug.Test.conn(:get, "/") |> init_session() |> SidebarCookie.call([])
      assert Plug.Conn.get_session(none, "sidebar_open") == true
    end

    test "on_mount assigns it to the socket, open when the session says nothing" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:cont, rail} = Shell.on_mount(:sidebar, %{}, %{"sidebar_open" => false}, socket)
      assert rail.assigns.sidebar_open == false

      assert {:cont, open} = Shell.on_mount(:sidebar, %{}, %{}, socket)
      assert open.assigns.sidebar_open == true
    end

    defp init_session(conn) do
      conn
      |> Plug.Test.init_test_session(%{})
    end
  end
end
