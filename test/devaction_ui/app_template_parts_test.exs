defmodule DevactionUI.AppTemplatePartsTest do
  @moduledoc "What an app screen asks of the components: a search and an account card in the sidebar, tabs with icons and chips, a quiet breadcrumb, a smaller title and an avatar with its own letters."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Avatar, Breadcrumb, PageHeader, Shell, Tabs}

  test "the sidebar search and the account card are drawn, the card named by the person" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Shell.sidebar_search>FIELD</Shell.sidebar_search>
      <Shell.sidebar_user name="Alex" email="alex@example.com" href="#me">
        <:avatar>AV</:avatar>
        <:icon>UP</:icon>
      </Shell.sidebar_user>
      """)

    assert html =~ "sidebar-search"
    assert html =~ "FIELD"
    assert html =~ ~s(aria-label="Alex")
    assert html =~ "alex@example.com"
    assert html =~ "sidebar-user-icon"
  end

  test "tabs take an icon slot, a chip for the count, a size and tabs with no panel content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Tabs.tabs id="t" variant={:line} size={:sm} counts={:chip} label="Sections">
        <:icon :let={tab}>ICON-{tab.id}</:icon>
        <:tab id="a" label="A" count="3" selected />
        <:tab id="b" label="B" />
      </Tabs.tabs>
      """)

    assert html =~ "ICON-a"
    assert html =~ "ICON-b"
    assert html =~ "h-10 text-sm"
    assert html =~ "rounded-md border border-line bg-wrap"
  end

  test "a breadcrumb can leave its links without the underline" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Breadcrumb.breadcrumb
        label="Trail"
        underline={false}
        items={[%{label: "Work", href: "/work"}, %{label: "Projects"}]}
      />
      """)

    refute html =~ "underline-offset-2"
    assert html =~ "Work"
  end

  test "a page header has a 28px title when it is inside an app shell" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PageHeader.page_header id="h" size={:md}>
        <:title>Projects</:title>
      </PageHeader.page_header>
      """)

    assert html =~ "text-[1.75rem]"
    refute html =~ "page-title"
  end

  test "an avatar can draw its own letters and the solid ink tone" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar name="SGE Church Management" initials="S" tone={:ink} />
      """)

    assert html =~ ~r/aria-hidden="true">S</
    assert html =~ "bg-ink"
    assert html =~ "text-card"
  end
end
