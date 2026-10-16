defmodule DevactionUI.NotificationCenterTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.NotificationCenter

  defp item(id, unread),
    do: %{id: id, title: "Title #{id}", meta: "meta #{id}", tone: :warn, unread: unread}

  defp render_panel(groups) do
    assigns = %{
      groups: groups,
      tabs: [%{id: "all", label: "All", count: 2}, %{id: "mentions", label: "Mentions", count: 0}]
    }

    rendered_to_string(~H"""
    <NotificationCenter.panel
      id="n"
      title="Notifications"
      read_all_label="Mark all as read"
      read_all_event="read_all"
      tabs_label="Filter"
      tabs={@tabs}
      tab="all"
      tab_event="tab"
      groups={@groups}
      unread_label="Unread"
      empty_label="Nothing here."
      open_event="open"
      preferences_label="Preferences"
      all_label="See all"
      target="#host"
    >
      <:icon :let={item}>icon-{item.id}</:icon>
    </NotificationCenter.panel>
    """)
  end

  test "renders the groups, the rows with the icon slot and the events through attrs" do
    html =
      render_panel([%{id: "today", label: "TODAY", items: [item("1", true), item("2", false)]}])

    assert html =~ ~s(aria-labelledby="n-title")
    assert html =~ ~s(phx-hook="DevactionUI.NotificationCenter")
    assert html =~ "TODAY"
    assert html =~ "icon-1"
    assert html =~ ~s(phx-click="open")
    assert html =~ ~s(phx-value-id="1")
    assert html =~ ~s(phx-target="#host")
    assert html =~ ~s(phx-click="read_all")
  end

  test "an unread row has the tint hook, the heavier title and the dot with its label" do
    html = render_panel([%{id: "d", label: "D", items: [item("1", true), item("2", false)]}])

    assert html =~ ~s(data-unread="true")
    assert html =~ ~s(data-unread="false")
    assert length(String.split(html, ~s(aria-label="Unread"))) == 2
    assert html =~ "font-medium"
  end

  test "the selected tab is the only one in the tab order and a zero count is hidden" do
    html = render_panel([%{id: "d", label: "D", items: [item("1", true)]}])

    assert length(String.split(html, ~s(tabindex="0"))) == 2
    assert length(String.split(html, ~s(tabindex="-1"))) == 2
    assert length(String.split(html, ~s(class="notif-count"))) == 2
  end

  test "with nothing unread the read-all action is disabled" do
    unread = render_panel([%{id: "d", label: "D", items: [item("1", true)]}])
    read = render_panel([%{id: "d", label: "D", items: [item("1", false)]}])

    refute unread =~ "disabled"
    assert read =~ "disabled"
  end

  test "an empty list says so" do
    assert render_panel([]) =~ "Nothing here."
  end
end
