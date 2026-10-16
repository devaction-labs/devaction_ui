defmodule DevactionUI.PaginationTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Pagination

  describe "entries/2" do
    test "a page past the last is clamped, so the current page stays in the window" do
      assert entries(12, 10) == [1, :gap, 9, 10]
    end

    test "a page before the first is clamped to the first" do
      assert entries(0, 10) == [1, 2, :gap, 10]
      assert entries(-4, 3) == [1, 2, 3]
    end
  end

  describe "pagination/1" do
    test "marks only the current page and names the navigation and its arrows" do
      assigns = %{path: &"/p?page=#{&1}"}

      html =
        rendered_to_string(
          ~H|<.pagination page={2} pages={3} path={@path} label="Pages" previous="Back" next="Forward" />|
        )

      assert html =~ ~s(aria-label="Pages")
      assert html =~ ~s(aria-label="Back")
      assert html =~ ~s(aria-label="Forward")
      assert length(String.split(html, ~s(aria-current="page"))) == 2
      assert html =~ ~r/aria-current="page"[^>]*>\s*2\s*</
    end

    test "draws nothing for one page or none" do
      assigns = %{path: & &1}

      for pages <- [0, 1] do
        assigns = Map.put(assigns, :pages, pages)

        html =
          rendered_to_string(
            ~H|<.pagination page={1} pages={@pages} path={@path} label="P" previous="a" next="b" />|
          )

        refute html =~ "<nav"
      end
    end

    test "global attributes reach the nav" do
      assigns = %{path: & &1}

      html =
        rendered_to_string(
          ~H|<.pagination id="pg" data-x="1" page={1} pages={3} path={@path} label="P" previous="a" next="b" />|
        )

      assert html =~ ~s(id="pg")
      assert html =~ ~s(data-x="1")
    end

    test "the icon slots replace the typographic arrows" do
      assigns = %{path: & &1}

      html =
        rendered_to_string(~H"""
        <.pagination page={2} pages={3} path={@path} label="P" previous="a" next="b">
          <:previous_icon><i>PREV</i></:previous_icon>
          <:next_icon><i>NEXT</i></:next_icon>
        </.pagination>
        """)

      assert html =~ "PREV" and html =~ "NEXT"
      refute html =~ "‹"
      refute html =~ "›"
    end

    test "without icon slots the arrows are 14px inline chevrons, never glyphs" do
      assigns = %{path: & &1}

      html =
        rendered_to_string(
          ~H|<.pagination page={2} pages={3} path={@path} label="P" previous="a" next="b" />|
        )

      assert length(Regex.scan(~r/<svg[^>]*size-3\.5/, html)) == 2
      assert html =~ "stroke-width=\"2\""
      assert html =~ "rtl:-scale-x-100"
      assert html =~ ~s(d="m15 6-6 6 6 6")
      assert html =~ ~s(d="m9 6 6 6-6 6")
      refute html =~ "‹"
      refute html =~ "›"
    end

    test "the page is clamped when it is past the last one" do
      assigns = %{path: &"/p?page=#{&1}"}

      html =
        rendered_to_string(
          ~H|<.pagination page={12} pages={10} path={@path} label="P" previous="a" next="b" />|
        )

      assert html =~ ~r/aria-current="page"[^>]*>\s*10\s*</
      refute html =~ ~r/<a[^>]*aria-label="b"/
      assert html =~ ~r/<span[^>]*aria-disabled="true"[^>]*aria-label="b"/
    end

    test "the size sets the cells of the links and of the gap" do
      assigns = %{path: & &1}

      md =
        rendered_to_string(
          ~H|<.pagination page={5} pages={9} path={@path} label="P" previous="a" next="b" />|
        )

      sm =
        rendered_to_string(
          ~H|<.pagination size={:sm} page={5} pages={9} path={@path} label="P" previous="a" next="b" />|
        )

      assert md =~ "size-[38px]" and md =~ "h-[38px]"
      assert sm =~ "size-[30px]" and sm =~ "h-[30px]"
      refute sm =~ "size-[38px]"
    end

    test "kind picks how a link goes to its page" do
      assigns = %{path: &"/p?page=#{&1}"}

      patch =
        rendered_to_string(
          ~H|<.pagination page={1} pages={3} path={@path} label="P" previous="a" next="b" />|
        )

      navigate =
        rendered_to_string(
          ~H|<.pagination kind={:navigate} page={1} pages={3} path={@path} label="P" previous="a" next="b" />|
        )

      href =
        rendered_to_string(
          ~H|<.pagination kind={:href} page={1} pages={3} path={@path} label="P" previous="a" next="b" />|
        )

      assert patch =~ ~s(data-phx-link="patch")
      assert navigate =~ ~s(data-phx-link="redirect")
      refute href =~ "data-phx-link"
      assert href =~ ~s(href="/p?page=2")
    end
  end
end
