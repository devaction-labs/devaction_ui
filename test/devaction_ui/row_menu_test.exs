defmodule DevactionUI.RowMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.{Dropdown, RowMenu}

  defp has?(html, selector),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.count() > 0

  defp attribute(html, selector, name),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> LazyHTML.attribute(name)

  defp menu(extra \\ %{}) do
    assigns = Map.merge(%{align: :end, target: nil}, extra)

    rendered_to_string(~H"""
    <RowMenu.row_menu
      id="row-7"
      label="Actions"
      trigger_label="Actions for PR 214"
      align={@align}
      target={@target}
      data-row="7"
    >
      <:trigger>DOTS</:trigger>
      <:item event="open" shortcut="↵">Open</:item>
      <:item event="rename" value="r" values={%{id: 7}} separator>Rename</:item>
      <:item navigate="/pr/214">See PR</:item>
      <:item event="delete" danger separator>Delete</:item>
    </RowMenu.row_menu>
    """)
  end

  test "is a fixed dropdown with an icon button named by trigger_label" do
    html = menu()

    assert has?(html, "#row-7[phx-hook='DevactionUI.Dropdown'][data-fixed=true][data-row='7']")
    assert has?(html, "button[data-trigger][aria-haspopup=menu][aria-label='Actions for PR 214']")
    assert html =~ "DOTS"
    assert has?(html, "#row-7-menu[role=menu][aria-label=Actions][hidden]")
  end

  test "the menu is fixed to the window, above the sticky cells of a table" do
    classes = attribute(menu(), "#row-7-menu", "class") |> List.first()

    assert classes =~ "fixed"
    assert classes =~ "z-50"
    refute classes =~ "absolute"
  end

  test "opens to the end of the button unless told otherwise" do
    assert attribute(menu(), "#row-7", "data-align") == ["end"]
    assert attribute(menu(%{align: :start}), "#row-7", "data-align") == ["start"]
  end

  test "takes the items of a dropdown: actions, links, separators, shortcuts and danger" do
    html = menu()

    assert has?(html, "button[role=menuitem][phx-click=open]")
    assert has?(html, "button[phx-click=rename][phx-value-choice=r][phx-value-id='7']")
    assert has?(html, "a[role=menuitem][href='/pr/214']")
    assert has?(html, "[role=separator]")
    assert html =~ "↵"
    assert html =~ "text-tag-risk-text"
  end

  test "the actions go to the target" do
    assert has?(menu(%{target: "#table"}), "button[phx-click=open][phx-target='#table']")
  end

  test "a plain dropdown stays absolute and is not fixed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Dropdown.dropdown id="d" label="Sort">
        <:trigger>Sort</:trigger>
        <:item event="a">A</:item>
      </Dropdown.dropdown>
      """)

    assert has?(html, "#d[data-fixed=false]")
    assert attribute(html, "#d-menu", "class") |> List.first() =~ "absolute"
  end
end
