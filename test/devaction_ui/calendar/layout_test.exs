defmodule DevactionUI.Calendar.LayoutTest do
  @moduledoc "Where the events of a day go in a column of hours."
  use ExUnit.Case, async: true

  alias DevactionUI.Calendar.Layout

  defp event(id, from, to \\ nil) do
    %{id: id, starts_at: from, ends_at: to}
  end

  defp by_id(placed, id), do: Enum.find(placed, &(&1.event.id == id))

  test "an event is placed by its time and length, in percents of the hours shown" do
    [placed] = Layout.place([event("a", ~T[09:00:00], ~T[10:30:00])], 8..13)

    assert placed.top == Float.round(60 / 360 * 100, 3)
    assert placed.height == 25.0
    assert {placed.left, placed.width} == {0.0, 100.0}
  end

  test "an event without an end lasts half an hour and one that ends before it starts lasts a quarter" do
    placed =
      Layout.place(
        [event("a", ~T[08:00:00]), event("b", ~T[10:00:00], ~T[09:00:00])],
        8..11
      )

    assert by_id(placed, "a").height == Float.round(30 / 240 * 100, 3)
    assert by_id(placed, "b").height == Float.round(15 / 240 * 100, 3)
  end

  test "events that overlap share the width and the ones apart keep all of it" do
    placed =
      Layout.place(
        [
          event("a", ~T[09:00:00], ~T[10:00:00]),
          event("b", ~T[09:30:00], ~T[10:30:00]),
          event("c", ~T[12:00:00], ~T[13:00:00])
        ],
        8..13
      )

    assert {by_id(placed, "a").left, by_id(placed, "a").width} == {0.0, 50.0}
    assert {by_id(placed, "b").left, by_id(placed, "b").width} == {50.0, 50.0}
    assert {by_id(placed, "c").left, by_id(placed, "c").width} == {0.0, 100.0}
  end

  test "an event that fits the gap of another one reuses its column" do
    placed =
      Layout.place(
        [
          event("long", ~T[09:00:00], ~T[12:00:00]),
          event("one", ~T[09:00:00], ~T[10:00:00]),
          event("two", ~T[10:00:00], ~T[11:00:00])
        ],
        8..13
      )

    assert Enum.all?(placed, &(&1.width == 50.0))
    assert by_id(placed, "one").left == by_id(placed, "two").left
    assert by_id(placed, "long").left != by_id(placed, "one").left
  end

  test "an event is cut at the edge of the range, and one outside or without a start is not placed" do
    placed =
      Layout.place(
        [
          event("early", ~T[07:00:00], ~T[09:00:00]),
          event("late", ~T[13:30:00], ~T[15:00:00]),
          event("out", ~T[15:00:00], ~T[16:00:00]),
          %{id: "all-day"}
        ],
        8..13
      )

    assert placed |> Enum.map(& &1.event.id) |> Enum.sort() == ["early", "late"]
    early = by_id(placed, "early")
    assert {early.top, early.height} == {0.0, Float.round(60 / 360 * 100, 3)}
    late = by_id(placed, "late")
    assert Float.round(late.top + late.height, 3) == 100.0
  end

  test "minutes counts from midnight" do
    assert Layout.minutes(~T[01:30:00]) == 90
  end
end
