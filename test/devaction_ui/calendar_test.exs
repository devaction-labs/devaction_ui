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
      assert Calendar.title(~D[2026-10-15], :month) == "10/2026"
      assert Calendar.title(~D[2026-10-15], :week) == "11/10 – 17/10/2026"
      assert Calendar.title(~D[2026-10-15], :week, :monday) == "12/10 – 18/10/2026"
    end
  end

  describe "the grid" do
    defp calendar(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            date: ~D[2026-10-15],
            view: :month,
            cell_label: nil,
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
        cell_label={@cell_label}
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
      assert html =~ "bg-wrap/40 text-muted-2"
      assert html =~ ~s(aria-label="15/10/2026: M3, Invoice, Review, Extra")
      assert html =~ ~s(aria-label="03/10/2026")
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

    test "a cell is named by the function of the caller" do
      html = calendar(%{cell_label: fn day, events -> "#{day.day}/#{length(events)}" end})

      assert html =~ ~s(aria-label="15/4")
      assert html =~ ~s(aria-label="2/1")
    end

    test "days of the other months show no events, and the dot is nearly square" do
      html =
        calendar(%{events: [%{id: "x", date: ~D[2026-09-29], label: "Out", kind: :ok}]})

      refute html =~ ~s(data-event="x")
      refute html =~ "Out"
      assert calendar() =~ "rounded-[2px]"
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

  describe "the week with hours" do
    defp hours_calendar(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            hours: 8..13,
            weekend: true,
            hour_label: nil,
            weekdays: ~w(MON TUE WED THU FRI SAT SUN),
            events: [
              %{
                id: "a",
                date: ~D[2026-10-13],
                label: "Daily",
                kind: :chart_3,
                starts_at: ~T[09:00:00],
                ends_at: ~T[09:30:00],
                detail: "Carlos"
              },
              %{
                id: "b",
                date: ~D[2026-10-13],
                label: "Review",
                kind: :info,
                starts_at: ~T[09:15:00],
                ends_at: ~T[10:15:00]
              },
              %{id: "c", date: ~D[2026-10-14], label: "Holiday", kind: :chart_1}
            ]
          },
          extra
        )

      rendered_to_string(~H"""
      <Calendar.calendar
        id="c"
        label="Deliveries"
        title="Week"
        date={~D[2026-10-15]}
        view={:week}
        week_start={:monday}
        hours={@hours}
        weekend={@weekend}
        hour_label={@hour_label}
        today={~D[2026-10-15]}
        events={@events}
        weekdays={@weekdays}
        more_label="+%{count}"
        prev_label="Previous"
        next_label="Next"
        select_event="select"
        prev_event="prev"
        next_event="next"
      >
        <:legend kind={:chart_1}>Milestone</:legend>
        <:legend kind={:chart_3}>Meeting</:legend>
      </Calendar.calendar>
      """)
    end

    test "is a grid with the hours column, a header per day and a cell per day" do
      html = hours_calendar()

      assert html =~ ~s(role="grid")
      assert html =~ "calendar-hours"
      assert html =~ "--cal-days: 7; --cal-hours: 6"
      assert html =~ ~s(data-columns="7")
      assert length(Regex.scan(~r/role="columnheader"/, html)) == 7
      assert length(Regex.scan(~r/role="gridcell"/, html)) == 7
      assert html =~ "MON 12"
      assert html =~ "08:00"
      assert html =~ "13:00"
      refute html =~ "14:00"
    end

    test "weekend false keeps the five working days" do
      html = hours_calendar(%{weekend: false, weekdays: ~w(MON TUE WED THU FRI)})

      assert html =~ "--cal-days: 5"
      assert length(Regex.scan(~r/role="gridcell"/, html)) == 5
      refute html =~ "2026-10-17"
    end

    test "the hours are named by the caller when it gives a function" do
      html = hours_calendar(%{hour_label: fn hour -> "#{hour}h" end})

      assert html =~ "8h"
      refute html =~ "08:00"
    end

    test "events are placed by their time, side by side when they overlap, with a detail line" do
      html = hours_calendar()

      assert html =~
               ~r/data-event="a"[^>]*style="top: 16.667%; height: 8.333%; left: calc\(0.0% \+ 2px\); width: calc\(50.0% - 4px\)"/s

      assert html =~ ~r/data-event="b"[^>]*left: calc\(50.0% \+ 2px\)/s
      assert html =~ "Carlos"
      assert html =~ "border-l-chart-3!"
      assert html =~ "bg-chart-3/10"
      assert html =~ "border-l-learn!"
    end

    test "an event without a time sits in the all-day strip, hidden from the cells" do
      html = hours_calendar()

      assert html =~ ~r/aria-hidden="true"[^>]*>\s*<span[^>]*data-event="c"/s
      refute hours_calendar(%{events: []}) =~ "border-b border-l border-line p-1"
    end

    test "a cell keeps the name with all its events, today, and the tab order" do
      html = hours_calendar()

      assert html =~ ~s(aria-label="13/10/2026: Daily, Review")
      assert length(Regex.scan(~r/tabindex="0"/, html)) == 1
      assert html =~ ~r/id="c-day-2026-10-15"[^>]*aria-current="date"/s
    end

    test "the legend names the kinds with their colour" do
      html = hours_calendar()

      assert html =~ "Milestone"
      assert html =~ "Meeting"
      assert html =~ "bg-chart-1"
    end

    test "without hours the week keeps its cells" do
      refute calendar(%{view: :week}) =~ "calendar-hours"
    end
  end

  describe "the chart kinds and the header" do
    test "the four categories colour the chips of the month" do
      html =
        calendar(%{
          events: [
            %{id: "x", date: ~D[2026-10-02], label: "A", kind: :chart_1},
            %{id: "y", date: ~D[2026-10-02], label: "B", kind: :chart_4}
          ]
        })

      assert html =~ "bg-chart-1/10"
      assert html =~ "bg-chart-4/10"
    end

    test "the arrows are 36px with a 9px radius and the title is centred between them" do
      html = calendar()

      assert html =~ "rounded-[9px] border border-line-strong"
      assert html =~ "min-w-35 text-center text-base font-semibold"
    end
  end
end
