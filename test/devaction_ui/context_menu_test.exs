defmodule DevactionUI.ContextMenuTest do
  @moduledoc "The context menu: the hook and its target, the items, and the \"···\" menu that shares them."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.ContextMenu

  defp menu(extra \\ %{}) do
    assigns = Map.merge(%{more_label: nil, focusable: true}, extra)

    rendered_to_string(~H"""
    <ContextMenu.menu id="cm" label="Task actions" more_label={@more_label} focusable={@focusable}>
      <:area>Migrate old milestones</:area>
      <:more>MORE-ICON</:more>
      <:item event="open" shortcut="↵">Open</:item>
      <:item event="assign" value="me" values={%{id: 7}} separator>Assign to…</:item>
      <:item navigate="/pr/214" heading="Review">See PR</:item>
      <:item event="delete" danger separator>Delete task</:item>
      <:item event="archive" disabled>Archive</:item>
    </ContextMenu.menu>
    """)
  end

  test "is a hooked wrapper around the target area and a hidden menu" do
    html = menu()

    assert html =~ ~s(phx-hook="DevactionUI.ContextMenu")
    assert html =~ "data-target"
    assert html =~ "Migrate old milestones"
    assert html =~ "data-context-menu"
    assert html =~ ~s(role="menu")
    assert html =~ ~s(aria-label="Task actions")
    assert html =~ ~r/data-context-menu[^>]*hidden/s
  end

  test "the area is in the Tab order, unless the caller says its content already is" do
    assert menu() =~ ~s(tabindex="0")
    refute menu(%{focusable: false}) =~ ~s(tabindex="0")
    assert menu() =~ ~s(aria-haspopup="menu")
  end

  test "every item is a menu item, with its shortcut, separator, heading and danger colour" do
    html = menu()

    assert html =~ ~s(role="menuitem")
    assert html =~ "Open"
    assert html =~ "↵"
    assert html =~ ~s(role="separator")
    assert html =~ "Review"
    assert html =~ ~s(href="/pr/214")
    assert html =~ "text-tag-risk-text"
  end

  test "an item sends its event, its choice and its values" do
    html = menu()

    assert html =~ ~s(phx-click="assign")
    assert html =~ ~s(phx-value-choice="me")
    assert html =~ ~s(phx-value-id="7")
  end

  test "a disabled item stays out of the keys" do
    assert menu() =~ ~r/aria-disabled="true"/
  end

  test "has no dropdown button without a label for it" do
    refute menu() =~ "cm-more"
    refute menu(%{more_label: nil}) =~ ~s(phx-hook="DevactionUI.Dropdown")
  end

  test "with a label the same items also open from a \"···\" dropdown" do
    html = menu(%{more_label: "More actions"})

    assert html =~ ~s(phx-hook="DevactionUI.Dropdown")
    assert html =~ ~s(aria-label="More actions")
    assert html =~ "MORE-ICON"
    assert length(Regex.scan(~r/phx-click="delete"/, html)) == 2
    assert length(Regex.scan(~r/phx-click="open"/, html)) == 2
    assert length(Regex.scan(~r/href="\/pr\/214"/, html)) == 2
  end

  test "sends its events to the target of a LiveComponent" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <ContextMenu.menu id="cm2" label="Actions" target="#panel">
        <:area>Row</:area>
        <:item event="open">Open</:item>
      </ContextMenu.menu>
      """)

    assert html =~ ~s(phx-target="#panel")
  end

  test "passes the caller's own attributes to the wrapper" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <ContextMenu.menu id="cm3" label="Actions" data-row="9">
        <:area>Row</:area>
        <:item event="open">Open</:item>
      </ContextMenu.menu>
      """)

    assert html =~ ~s(data-row="9")
  end
end
