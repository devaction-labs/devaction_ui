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
end
