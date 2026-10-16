defmodule DevactionUI.BreadcrumbTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import DevactionUI.Breadcrumb

  defp render_trail(items) do
    assigns = %{items: items}
    rendered_to_string(~H|<.breadcrumb label="Here" items={@items} />|)
  end

  test "each item goes where it says: to, patch or href" do
    html =
      render_trail([
        %{label: "A", to: "/a"},
        %{label: "B", patch: "/b"},
        %{label: "C", href: "/c"},
        %{label: "D"}
      ])

    assert html =~ ~r/<a href="\/a" data-phx-link="redirect"/
    assert html =~ ~r/<a href="\/b" data-phx-link="patch"/
    assert html =~ ~r/<a href="\/c" class=/
  end

  test "the last item is the current page even when it is a link" do
    html = render_trail([%{label: "A", to: "/a"}, %{label: "B", to: "/b"}])

    assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
    assert html =~ ~r/<a[^>]*aria-current="page"[^>]*>\s*B\s*<\/a>/
  end

  test "the last item without a destination is the current page and the earlier ones are not" do
    html = render_trail([%{label: "A"}, %{label: "B"}])

    assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
    assert html =~ ~r/<span aria-current="page" class="text-ink">\s*B\s*<\/span>/
    refute html =~ ~r/<span aria-current="page"[^>]*>\s*A/
  end

  test "links have a hover and a focus ring" do
    html = render_trail([%{label: "A", to: "/a"}, %{label: "B"}])

    assert html =~ "hover:text-ink"
    assert html =~ "focus-visible:ring-4"
  end

  test "the nav is named and takes global attributes" do
    assigns = %{items: [%{label: "A"}]}

    html =
      rendered_to_string(~H|<.breadcrumb label="You are here" id="bc" items={@items} />|)

    assert html =~ ~s(aria-label="You are here")
    assert html =~ ~s(id="bc")
  end

  test "the separator is text by default and any text through the attribute" do
    items = [%{label: "A", to: "/a"}, %{label: "B"}]

    assert render_trail(items) =~ ~s(<span aria-hidden="true">/</span>)

    assigns = %{items: items}
    html = rendered_to_string(~H|<.breadcrumb label="Here" separator=">" items={@items} />|)

    assert html =~ ~s(<span aria-hidden="true">&gt;</span>)
    refute html =~ ">/<"
  end

  test "the chevron separator mirrors itself in a right-to-left page" do
    assigns = %{items: [%{label: "A", to: "/a"}, %{label: "B"}]}

    html =
      rendered_to_string(~H|<.breadcrumb label="Here" separator={:chevron} items={@items} />|)

    assert html =~ "rtl:-scale-x-100"
    assert html =~ ~s(aria-hidden="true")
    assert html =~ "<svg"
  end

  defp render_long(max) do
    assigns = %{max: max}

    items =
      for n <- 1..6, do: %{label: "L#{n}", to: "/#{n}"}

    assigns = Map.put(assigns, :items, items)

    rendered_to_string(~H"""
    <.breadcrumb label="Here" items={@items} max={@max} collapsed_label="Show hidden pages" />
    """)
  end

  test "a long trail keeps the first item and the last ones and collapses the middle" do
    html = render_long(3)

    assert html =~ ~r/>\s*L1\s*</
    assert html =~ ~r/>\s*L5\s*</
    assert html =~ ~r/>\s*L6\s*</
    assert html =~ ~s(aria-label="Show hidden pages")
    assert html =~ "<details"

    [details] = Regex.run(~r/<details.*<\/details>/s, html)
    assert details =~ ~r/>\s*L2\s*</
    assert details =~ ~r/>\s*L4\s*</
    refute details =~ ~r/>\s*L5\s*</
    assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
  end

  test "the collapsed list has a hook that leaves its open state to the browser" do
    html = render_long(3)

    assert html =~ ~r/<details[^>]*id="breadcrumb-\d+-more"/
    assert html =~ ~s(phx-hook="DevactionUI.Breadcrumb")
    assert html =~ "ignore_attrs"
  end

  test "a trail that fits in max is not collapsed, and without max never is" do
    refute render_long(6) =~ "<details"
    refute render_long(nil) =~ "<details"
    refute render_trail([%{label: "A"}, %{label: "B"}]) =~ "<details"
  end

  test "max below 2 still keeps the first and the current item" do
    html = render_long(1)

    assert html =~ ~r/>\s*L1\s*</
    assert html =~ ~r/>\s*L6\s*</
    assert html =~ ~r/<details/
  end
end
