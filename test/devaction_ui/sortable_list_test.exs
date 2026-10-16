defmodule DevactionUI.SortableListTest do
  @moduledoc "The sortable list: its rows in the server's order, the handles, the buttons at the ends and the texts the hook says."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.SortableList

  defp list(extra \\ %{}) do
    assigns = Map.merge(%{event: "reorder", target: nil}, extra)

    rendered_to_string(~H"""
    <SortableList.list
      id="ms"
      label="Milestones"
      event={@event}
      target={@target}
      handle_label="Reorder"
      up_label="Move up"
      down_label="Move down"
      hint_label="Space picks up, arrows move, Space drops, Esc cancels"
      picked_label="__ITEM__ picked up, __POS__ of __TOTAL__"
      moved_label="__ITEM__ moved to __POS__ of __TOTAL__"
      dropped_label="__ITEM__ dropped at __POS__"
      cancelled_label="__ITEM__ back where it was"
    >
      <:handle_icon>GRIP</:handle_icon>
      <:up_icon>UP</:up_icon>
      <:down_icon>DOWN</:down_icon>
      <:row id="m1" label="Members" code="M1" status="delivered" />
      <:row id="m2" label="Tithes" code="M2" status="delivered" />
      <:row id="m3" label="Reports" code="M3" status="Oct 16" />
    </SortableList.list>
    """)
  end

  test "is a hooked wrapper around a named list with one row per slot, in the server's order" do
    html = list()

    assert html =~ ~s(phx-hook="DevactionUI.SortableList")
    assert html =~ ~s(aria-label="Milestones")
    assert length(Regex.scan(~r/data-sortable-row/, html)) == 3

    [m1, m2, m3] = Enum.map(~w(m1 m2 m3), &:binary.match(html, ~s(data-id="#{&1}")))
    assert elem(m1, 0) < elem(m2, 0)
    assert elem(m2, 0) < elem(m3, 0)
  end

  test "a row shows its code, its label and its status" do
    html = list()

    assert html =~ "M1"
    assert html =~ "Members"
    assert html =~ "Oct 16"
    assert html =~ ~s(data-label="Reports")
  end

  test "every handle is a button named by the row and described by the keyboard hint" do
    html = list()

    assert html =~ ~s(role="button")
    assert html =~ ~s(aria-label="Reorder Members")
    assert html =~ ~s(aria-describedby="ms-hint")
    assert html =~ ~s(id="ms-hint")
    assert html =~ "Space picks up"
    assert html =~ "GRIP"
  end

  test "the first row cannot go up and the last cannot go down" do
    [first, second, third] = list() |> String.split("data-sortable-row") |> tl()
    off = ~r/<button[^>]*data-move="(?<way>up|down)"[^>]*\sdisabled(\s|>)/

    assert Regex.named_captures(off, first)["way"] == "up"
    refute Regex.match?(off, second)
    assert Regex.named_captures(off, third)["way"] == "down"
  end

  test "the buttons are named by the row" do
    html = list()

    assert html =~ ~s(aria-label="Move up Tithes")
    assert html =~ ~s(aria-label="Move down Tithes")
    assert html =~ "UP"
    assert html =~ "DOWN"
  end

  test "hands the hook the event and the words it says, with their placeholders" do
    html = list()

    assert html =~ ~s(data-event="reorder")
    assert html =~ ~s(data-picked-label="__ITEM__ picked up, __POS__ of __TOTAL__")
    assert html =~ "data-moved-label"
    assert html =~ "data-dropped-label"
    assert html =~ "data-cancelled-label"
  end

  test "announces in a polite live region that LiveView leaves alone" do
    html = list()

    assert html =~ ~s(aria-live="polite")
    assert html =~ ~s(phx-update="ignore")
  end

  test "sends its event to the target of a LiveComponent, and the event can be renamed" do
    html = list(%{event: "milestones:order", target: "#panel"})

    assert html =~ ~s(phx-target="#panel")
    assert html =~ ~s(data-event="milestones:order")
  end

  test "uses glyphs when the caller gives no icons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <SortableList.list
        id="x"
        label="x"
        handle_label="h"
        up_label="u"
        down_label="d"
        hint_label="k"
        picked_label="p"
        moved_label="m"
        dropped_label="o"
        cancelled_label="c"
      >
        <:row id="a" label="A" />
        <:row id="b" label="B" />
      </SortableList.list>
      """)

    assert html =~ "⠿"
    assert html =~ "↑"
    assert html =~ "↓"
  end
end
