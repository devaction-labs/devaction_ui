defmodule DevactionUI.CalendarTest do
  @moduledoc "The calendar: the days it draws, the grid it makes and the events on it."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Calendar

  describe "the days" do
    test "a month is the weeks that hold its first and its last day, from the start of the week" do
      weeks = Calendar.month_weeks(2026, 10, :sunday)

      assert length(weeks) == 5
      assert Enum.all?(weeks, &(length(&1) == 7))
      assert weeks |> List.first() |> List.first() == ~D[2026-09-27]
      assert weeks |> List.last() |> List.last() == ~D[2026-10-31]
      assert [~D[2026-09-28] | _] = Calendar.month_weeks(2026, 10, :monday) |> List.first()
    end

    test "a month of exactly four weeks and one that needs six" do
      assert length(Calendar.month_weeks(2026, 2, :sunday)) == 4
      assert length(Calendar.month_weeks(2026, 8, :sunday)) == 6
    end

    test "a week is the seven days around a date" do
      assert Calendar.week_days(~D[2026-10-15], :sunday) |> then(&{hd(&1), List.last(&1)}) ==
               {~D[2026-10-11], ~D[2026-10-17]}

      assert Calendar.week_days(~D[2026-10-15], :monday) |> hd() == ~D[2026-10-12]
    end

    test "the month moves back and forward over the year" do
      assert Calendar.shift_month(~D[2026-10-15], -1) == ~D[2026-09-01]
      assert Calendar.shift_month(~D[2026-10-15], 1) == ~D[2026-11-01]
      assert Calendar.shift_month(~D[2026-01-10], -1) == ~D[2025-12-01]
      assert Calendar.shift_month(~D[2026-12-31], 1) == ~D[2027-01-01]
    end

    test "the title is neutral for a month and a week" do
      assert Calendar.title(~D[2026-10-15], :month) == "2026-10"
      assert Calendar.title(~D[2026-10-15], :week) == "2026-10-11 – 2026-10-17"
      assert Calendar.title(~D[2026-10-15], :week, :monday) == "2026-10-12 – 2026-10-18"
    end
  end

  describe "the grid" do
    defp calendar(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            date: ~D[2026-10-15],
            view: :month,
            selected: nil,
            today: ~D[2026-10-15],
            events: [
              %{id: "a", date: ~D[2026-10-15], label: "M3", kind: :warn},
              %{id: "b", date: ~D[2026-10-15], label: "Invoice", kind: :info},
              %{id: "c", date: ~D[2026-10-15], label: "Review", kind: :risk},
              %{id: "d", date: ~D[2026-10-15], label: "Extra", kind: :ok},
              %{id: "e", date: ~D[2026-10-02], label: "Done", kind: :ok}
            ]
          },
          extra
        )

      rendered_to_string(~H"""
      <Calendar.calendar
        id="c"
        label="Deliveries"
        title="October"
        date={@date}
        view={@view}
        today={@today}
        selected={@selected}
        events={@events}
        weekdays={~w(S M T W T F S)}
        more_label="+%{count} more"
        prev_label="Previous"
        next_label="Next"
        select_event="select"
        prev_event="prev"
        next_event="next"
      >
        <:prev_icon>&lt;</:prev_icon>
        <:next_icon>&gt;</:next_icon>
      </Calendar.calendar>
      """)
    end

    test "is a grid with headers, rows and cells, and the hook of the keyboard" do
      html = calendar()

      assert html =~ ~s(role="grid")
      assert html =~ ~s(aria-label="Deliveries")
      assert html =~ ~s(phx-hook="DevactionUI.Calendar")
      assert html =~ ~s(data-columns="7")
      assert length(Regex.scan(~r/role="columnheader"/, html)) == 7
      assert length(Regex.scan(~r/role="row"/, html)) == 6
      assert length(Regex.scan(~r/role="gridcell"/, html)) == 35
      assert html =~ ~s(phx-click="select")
      assert html =~ ~s(aria-label="Previous")
    end

    test "only one cell is in the tab order: the day selected, or today" do
      assert length(Regex.scan(~r/tabindex="0"/, calendar())) == 1
      assert calendar() =~ ~r/id="c-day-2026-10-15"[^>]*tabindex="0"/s

      selected = calendar(%{selected: ~D[2026-10-20]})
      assert selected =~ ~r/id="c-day-2026-10-20"[^>]*tabindex="0"/s
      assert selected =~ ~r/id="c-day-2026-10-20"[^>]*aria-selected="true"/s

      away = calendar(%{today: ~D[2025-01-01], selected: ~D[2025-02-02]})
      assert length(Regex.scan(~r/tabindex="0"/, away)) == 1
      assert away =~ ~r/id="c-day-2026-09-27"[^>]*tabindex="0"/s
    end

    test "marks today, dims the days of other months and names each day with its events" do
      html = calendar()

      assert html =~ ~r/id="c-day-2026-10-15"[^>]*aria-current="date"/s
      assert html =~ "bg-ink font-semibold"
      assert html =~ "bg-wrap/40 text-muted"
      assert html =~ ~s(aria-label="2026-10-15: M3, Invoice, Review, Extra")
      assert html =~ ~s(aria-label="2026-10-03")
    end

    test "events are chips coloured by kind, three at most with the rest counted" do
      html = calendar()

      assert html =~ ~s(data-event="a")
      assert html =~ ~s(data-event="c")
      refute html =~ ~s(data-event="d")
      assert html =~ "+1 more"
      assert html =~ "tag-warn"
      assert html =~ "tag-info"
      assert html =~ "tag-risk"
    end

    test "the week view lists every event of its days" do
      html = calendar(%{view: :week})

      assert length(Regex.scan(~r/role="gridcell"/, html)) == 7
      assert length(Regex.scan(~r/role="row"/, html)) == 2
      assert html =~ ~s(data-event="d")
      refute html =~ "more"
      assert html =~ "min-h-48"
    end
  end

  describe "the actions slot" do
    defp render_calendar(assigns) do
      ~H"""
      <Calendar.calendar
        id="c"
        label="Deliveries"
        title="October 2026"
        date={~D[2026-10-15]}
        today={~D[2026-10-15]}
        weekdays={~w(SUN MON TUE WED THU FRI SAT)}
        more_label="+%{count}"
        prev_label="Previous"
        next_label="Next"
        select_event="select"
        prev_event="prev"
        next_event="next"
      >
        <:actions :if={assigns[:switch]}><span id="view-switch">Month</span></:actions>
      </Calendar.calendar>
      """
    end

    test "it sits in the header beside the arrows when given" do
      html = rendered_to_string(render_calendar(%{switch: true}))

      assert html =~ ~s(id="view-switch")
      assert html =~ ~s(id="c-next")
    end

    test "the header has no empty box without it" do
      refute rendered_to_string(render_calendar(%{})) =~ "ml-2"
    end
  end
end
