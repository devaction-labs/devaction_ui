defmodule DevactionUI.Calendar do
  @moduledoc """
  A month or a week of days with their events, as an agenda of deliveries: each event is a coloured chip by kind
  (risk, warning, ok, info, neutral). It is a `grid` (`role="grid"`, rows, column headers, cells) with one cell in
  the tab order and the arrows, Home, End and Page keys moving between days (`DevactionUI.Calendar` hook);
  pressing a day, or Enter on it, sends `select_event` with `phx-value-date`, and the previous and next buttons
  send `prev_event` and `next_event`.

  The server owns the dates: `month_weeks/3` and `week_days/2` give the days to draw, so the grid is the same
  in the browser and in a test. The names of the months and of the days come from the caller (the library
  holds no language).
  """
  use Phoenix.Component

  alias DevactionUI.Tone

  @max_chips 3

  @doc "The weeks of a month, each a list of seven dates, from the week that holds the 1st to the one that holds the last day."
  @spec month_weeks(pos_integer(), 1..12, :sunday | :monday) :: [[Date.t()]]
  def month_weeks(year, month, week_start \\ :sunday) do
    first = Date.new!(year, month, 1)
    last = Date.end_of_month(first)

    first
    |> week_start_of(week_start)
    |> Stream.iterate(&Date.add(&1, 7))
    |> Enum.take_while(&(Date.compare(&1, last) != :gt))
    |> Enum.map(&week_days(&1, week_start))
  end

  @doc "The seven dates of the week `date` is in."
  @spec week_days(Date.t(), :sunday | :monday) :: [Date.t()]
  def week_days(date, week_start \\ :sunday) do
    start = week_start_of(date, week_start)
    for offset <- 0..6, do: Date.add(start, offset)
  end

  defp week_start_of(date, :monday), do: Date.beginning_of_week(date, :monday)
  defp week_start_of(date, :sunday), do: Date.beginning_of_week(date, :sunday)

  @doc "The first day of the month before and after the month of `date`."
  @spec shift_month(Date.t(), -1 | 1) :: Date.t()
  def shift_month(date, delta) do
    shifted(Date.beginning_of_month(date), delta)
  end

  defp shifted(first, delta) when delta < 0,
    do: first |> Date.add(-1) |> Date.beginning_of_month()

  defp shifted(first, _delta), do: first |> Date.end_of_month() |> Date.add(1)

  @doc "`2026-10` for a month and `2026-10-11 – 2026-10-17` for a week, the neutral form a caller can replace with its own words."
  @spec title(Date.t(), :month | :week, :sunday | :monday) :: String.t()
  def title(date, view, week_start \\ :sunday)
  def title(date, :month, _week_start), do: Calendar.strftime(date, "%Y-%m")

  def title(date, :week, week_start) do
    days = week_days(date, week_start)
    "#{Date.to_iso8601(List.first(days))} – #{Date.to_iso8601(List.last(days))}"
  end

  @type event :: %{id: String.t(), date: Date.t(), label: String.t(), kind: Tone.t()}

  attr :id, :string, required: true

  attr :label, :string,
    required: true,
    doc: "the name of the grid, e.g. `Deliveries in October 2026`"

  attr :title, :string, required: true, doc: "the month or the week, as written for the person"
  attr :date, :any, required: true, doc: "a date of the month (or of the week) shown"
  attr :view, :atom, values: [:month, :week], default: :month
  attr :week_start, :atom, values: [:sunday, :monday], default: :sunday
  attr :today, :any, required: true, doc: "a `Date`: today in the workspace's time zone"
  attr :selected, :any, default: nil
  attr :events, :list, default: [], doc: "`%{id, date, label, kind}` each"
  attr :weekdays, :list, required: true, doc: "seven short names, in the order of the week start"

  attr :more_label, :string,
    required: true,
    doc: "`+%{count} more`, with the count placed by the caller"

  attr :prev_label, :string, required: true
  attr :next_label, :string, required: true
  attr :select_event, :string, required: true
  attr :prev_event, :string, required: true
  attr :next_event, :string, required: true
  attr :class, :any, default: nil
  slot :prev_icon
  slot :next_icon
  slot :actions, doc: "controls beside the arrows, such as a month and week switch"

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def calendar(assigns) do
    weeks =
      case assigns.view do
        :month -> month_weeks(assigns.date.year, assigns.date.month, assigns.week_start)
        :week -> [week_days(assigns.date, assigns.week_start)]
      end

    by_day = Enum.group_by(assigns.events, & &1.date)
    focus = focus_date(assigns, weeks)
    assigns = assign(assigns, weeks: weeks, by_day: by_day, focus: focus, max: @max_chips)

    ~H"""
    <div id={@id} class={["flex flex-col gap-3", @class]} {@rest}>
      <div class="flex items-center justify-between gap-2">
        <h3 id={"#{@id}-title"} class="m-0 text-lg font-semibold text-ink">{@title}</h3>
        <div class="flex items-center gap-1">
          <button
            id={"#{@id}-prev"}
            type="button"
            aria-label={@prev_label}
            phx-click={@prev_event}
            phx-target={@target}
            class="grid size-9 place-items-center rounded-[10px] border border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {render_slot(@prev_icon)}
          </button>
          <button
            id={"#{@id}-next"}
            type="button"
            aria-label={@next_label}
            phx-click={@next_event}
            phx-target={@target}
            class="grid size-9 place-items-center rounded-[10px] border border-line bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
          >
            {render_slot(@next_icon)}
          </button>
          <div :if={@actions != []} class="ml-2">{render_slot(@actions)}</div>
        </div>
      </div>
      <div
        id={"#{@id}-grid"}
        role="grid"
        aria-labelledby={"#{@id}-title"}
        aria-label={@label}
        phx-hook="DevactionUI.Calendar"
        data-columns="7"
        class="calendar"
      >
        <div role="row" class="contents">
          <div
            :for={name <- @weekdays}
            role="columnheader"
            class="border-r border-b border-line bg-wrap/60 px-2 py-1.5 text-center font-mono text-[11px] tracking-[0.08em] text-muted"
          >
            {name}
          </div>
        </div>
        <div :for={week <- @weeks} role="row" class="contents">
          <div
            :for={day <- week}
            id={"#{@id}-day-#{Date.to_iso8601(day)}"}
            role="gridcell"
            tabindex={tab_index(day == @focus)}
            data-date={Date.to_iso8601(day)}
            aria-selected={to_string(day == @selected)}
            aria-current={day == @today && "date"}
            aria-label={cell_label(day, Map.get(@by_day, day, []))}
            phx-click={@select_event}
            phx-target={@target}
            phx-value-date={Date.to_iso8601(day)}
            class={[
              "calendar-cell cursor-pointer outline-none focus-visible:relative focus-visible:z-10 focus-visible:ring-4 focus-visible:ring-ink/10",
              @view == :week && "min-h-48",
              @view == :month && day.month != @date.month && "bg-wrap/40 text-muted"
            ]}
          >
            <span class={[
              "flex size-6 items-center justify-center rounded-full text-[13px]",
              day == @today && "bg-ink font-semibold text-on-primary"
            ]}>
              {day.day}
            </span>
            <% events = Map.get(@by_day, day, []) %>
            <span
              :for={event <- visible(events, @view, @max)}
              data-event={event.id}
              class={["calendar-event", Tone.surface(event.kind), Tone.text(event.kind)]}
            >
              <span
                class={["size-1.5 shrink-0 rounded-full", Tone.fill(event.kind)]}
                aria-hidden="true"
              />
              <span class="truncate">{event.label}</span>
            </span>
            <span
              :if={@view == :month and length(events) > @max}
              class="px-1.5 text-[11px] text-muted"
            >
              {String.replace(@more_label, "%{count}", to_string(length(events) - @max))}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp focus_date(%{selected: selected, today: today}, weeks) do
    cond do
      Enum.any?(weeks, &(selected in &1)) -> selected
      Enum.any?(weeks, &(today in &1)) -> today
      true -> first_of(weeks)
    end
  end

  defp tab_index(true), do: "0"
  defp tab_index(false), do: "-1"

  defp visible(events, :week, _max), do: events
  defp visible(events, _view, max), do: Enum.take(events, max)

  defp first_of(weeks), do: weeks |> List.first() |> List.first()

  defp cell_label(day, events) do
    base = Date.to_iso8601(day)

    case events do
      [] -> base
      list -> "#{base}: #{Enum.map_join(list, ", ", & &1.label)}"
    end
  end
end
