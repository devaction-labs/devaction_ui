defmodule DevactionUI.Calendar do
  @moduledoc """
  A month or a week of days with their events, as an agenda of deliveries: each event is a coloured chip by kind
  (risk, warning, ok, info, neutral). It is a `grid` (`role="grid"`, rows, column headers, cells) with one cell in
  the tab order and the arrows, Home, End and Page keys moving between days (`DevactionUI.Calendar` hook);
  pressing a day, or Enter on it, sends `select_event` with `phx-value-date`, and the previous and next buttons
  send `prev_event` and `next_event`.

  The server owns the dates: `month_weeks/3` and `week_days/2` give the days to draw, so the grid is the same
  in the browser and in a test. The names of the months and of the days come from the caller (the library
  holds no language): `title` is written by the caller, and `cell_label` (a function of the day and its events)
  names each cell for screen readers.

  The week view is the seven days of the week as cells with all their events as chips, or, when `hours` is
  given (a range such as `8..17`, the last hour included), a grid of hours: a time column, a column per day
  (`weekend={false}` drops Saturday and Sunday, and the caller then gives five `weekdays`) and each event with a
  `starts_at` (and an `ends_at`, a `Time`) drawn at its time with its length, the ones that overlap side by
  side (`DevactionUI.Calendar.Layout`). An event without a `starts_at` is an all-day one and sits in a strip
  above the hours; `detail` is a second line under the label. Days outside the shown month are drawn dimmed
  and without events.

  Event kinds are the tones of `DevactionUI.Tone` or the four categories `:chart_1` to `:chart_4`, drawn in the
  `--chart-*` colours; the `legend` slot names the kinds in use under the grid.
  """
  use Phoenix.Component

  alias DevactionUI.Calendar.Layout
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

  @doc "`10/2026` for a month and `11/10 – 17/10/2026` for a week, the neutral form a caller replaces with its own words."
  @spec title(Date.t(), :month | :week, :sunday | :monday) :: String.t()
  def title(date, view, week_start \\ :sunday)
  def title(date, :month, _week_start), do: Calendar.strftime(date, "%m/%Y")

  def title(date, :week, week_start) do
    days = week_days(date, week_start)

    "#{Calendar.strftime(List.first(days), "%d/%m")} – #{Calendar.strftime(List.last(days), "%d/%m/%Y")}"
  end

  @type kind :: Tone.t() | :chart_1 | :chart_2 | :chart_3 | :chart_4
  @type event :: %{
          required(:id) => String.t(),
          required(:date) => Date.t(),
          required(:label) => String.t(),
          required(:kind) => kind(),
          optional(:starts_at) => Time.t(),
          optional(:ends_at) => Time.t(),
          optional(:detail) => String.t()
        }

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

  attr :events, :list,
    default: [],
    doc:
      "`%{id, date, label, kind}` each, and `starts_at`, `ends_at` and `detail` for the hours grid"

  attr :hours, :any,
    default: nil,
    doc: "a range of hours such as `8..17`: the week view becomes a grid of hours"

  attr :weekend, :boolean,
    default: true,
    doc: "false drops Saturday and Sunday from the grid of hours"

  attr :hour_label, :any,
    default: nil,
    doc: "a function of an hour (0 to 23) returning the text of the time column; `HH:00` when nil"

  attr :weekdays, :list, required: true, doc: "seven short names, in the order of the week start"

  attr :more_label, :string,
    required: true,
    doc: "`+%{count} more`, with the count placed by the caller"

  attr :cell_label, :any,
    default: nil,
    doc:
      "a function of the day and its events returning the name of the cell for screen readers; `dd/mm/yyyy: labels` when nil"

  attr :prev_label, :string, required: true
  attr :next_label, :string, required: true
  attr :select_event, :string, required: true
  attr :prev_event, :string, required: true
  attr :next_event, :string, required: true
  attr :class, :any, default: nil
  slot :prev_icon
  slot :next_icon
  slot :actions, doc: "controls beside the arrows, such as a month and week switch"

  slot :legend, doc: "one entry per kind in use, drawn under the grid with its colour" do
    attr :kind, :atom, required: true
  end

  attr :target, :any,
    default: nil,
    doc: "a `phx-target` (a `@myself`) when used inside a LiveComponent"

  attr :rest, :global

  def calendar(assigns) do
    timed? = assigns.view == :week and assigns.hours != nil

    weeks =
      case assigns.view do
        :month -> month_weeks(assigns.date.year, assigns.date.month, assigns.week_start)
        :week -> [week_days(assigns.date, assigns.week_start)]
      end

    by_day = Enum.group_by(assigns.events, & &1.date)
    focus = focus_date(assigns, weeks)

    assigns =
      assign(assigns,
        weeks: weeks,
        by_day: by_day,
        focus: focus,
        max: @max_chips,
        timed?: timed?
      )

    ~H"""
    <div id={@id} class={["flex flex-col gap-3", @class]} {@rest}>
      <div class="flex flex-wrap items-center gap-2">
        <button
          id={"#{@id}-prev"}
          type="button"
          aria-label={@prev_label}
          phx-click={@prev_event}
          phx-target={@target}
          class="grid size-9 place-items-center rounded-[9px] border border-line-strong bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {render_slot(@prev_icon)}
        </button>
        <h3 id={"#{@id}-title"} class="m-0 min-w-35 text-center text-base font-semibold text-ink">
          {@title}
        </h3>
        <button
          id={"#{@id}-next"}
          type="button"
          aria-label={@next_label}
          phx-click={@next_event}
          phx-target={@target}
          class="grid size-9 place-items-center rounded-[9px] border border-line-strong bg-card text-ink-2 outline-none hover:bg-wrap focus-visible:ring-4 focus-visible:ring-ink/10"
        >
          {render_slot(@next_icon)}
        </button>
        <div :if={@actions != []} class="ml-2">{render_slot(@actions)}</div>
      </div>
      <.hours_grid :if={@timed?} {assigns} />
      <.cells_grid :if={not @timed?} {assigns} />
      <ul :if={@legend != []} class="m-0 flex list-none flex-wrap gap-4 p-0 text-xs text-ink-2">
        <li :for={item <- @legend} class="flex items-center gap-1.5">
          <span aria-hidden="true" class={["size-2 rounded-[2px]", fill(item.kind)]} />
          {render_slot(item)}
        </li>
      </ul>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, required: true
  attr :label, :string, required: true
  attr :columns, :integer, required: true
  attr :style, :string, default: nil
  slot :inner_block, required: true

  defp grid(assigns) do
    ~H"""
    <div
      id={"#{@id}-grid"}
      role="grid"
      aria-labelledby={"#{@id}-title"}
      aria-label={@label}
      phx-hook="DevactionUI.Calendar"
      data-columns={@columns}
      class={@class}
      style={@style}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp cells_grid(assigns) do
    ~H"""
    <.grid id={@id} label={@label} columns={7} class="calendar">
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
          aria-label={cell_label(@cell_label, day, shown(@by_day, day, @view, @date))}
          phx-click={@select_event}
          phx-target={@target}
          phx-value-date={Date.to_iso8601(day)}
          class={[
            "calendar-cell cursor-pointer outline-none focus-visible:relative focus-visible:z-10 focus-visible:ring-4 focus-visible:ring-ink/10",
            @view == :week && "min-h-48",
            @view == :month && day.month != @date.month && "bg-wrap/40 text-muted-2"
          ]}
        >
          <span class={[
            "flex size-6 items-center justify-center rounded-full text-xs",
            day == @today && "bg-ink font-semibold text-on-primary"
          ]}>
            {day.day}
          </span>
          <% events = shown(@by_day, day, @view, @date) %>
          <span
            :for={event <- visible(events, @view, @max)}
            data-event={event.id}
            class={["calendar-event", surface(event.kind), text(event.kind)]}
          >
            <span class={["size-1.5 shrink-0 rounded-[2px]", fill(event.kind)]} aria-hidden="true" />
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
    </.grid>
    """
  end

  defp hours_grid(assigns) do
    pairs = hours_days(assigns)
    days = Enum.map(pairs, fn {_name, day} -> day end)

    assigns =
      assign(assigns,
        pairs: pairs,
        days: days,
        all_day?: Enum.any?(days, &(all_day_events(assigns.by_day, &1) != [])),
        hour_list: Enum.to_list(assigns.hours),
        style: "--cal-days: #{length(days)}; --cal-hours: #{Range.size(assigns.hours)}"
      )

    ~H"""
    <.grid id={@id} label={@label} columns={length(@days)} class="calendar-hours" style={@style}>
      <div role="row" class="contents">
        <div role="presentation" class="calendar-hours-corner"></div>
        <div
          :for={{name, day} <- @pairs}
          role="columnheader"
          class={["calendar-hours-head", day == @today && "bg-wrap font-semibold"]}
        >
          {name} {day.day}
        </div>
      </div>
      <div :if={@all_day?} role="row" class="contents">
        <div role="presentation" class="calendar-hours-corner"></div>
        <div
          :for={day <- @days}
          role="presentation"
          aria-hidden="true"
          class="flex min-w-0 flex-col gap-1 border-b border-l border-line p-1"
        >
          <span
            :for={event <- all_day_events(@by_day, day)}
            data-event={event.id}
            class={["calendar-event", surface(event.kind), text(event.kind)]}
          >
            <span class={["size-1.5 shrink-0 rounded-[2px]", fill(event.kind)]} />
            <span class="truncate">{event.label}</span>
          </span>
        </div>
      </div>
      <div role="row" class="contents">
        <div role="presentation" aria-hidden="true" class="calendar-hours-times">
          <span :for={hour <- @hour_list} class="calendar-hours-time">
            {hour_label(@hour_label, hour)}
          </span>
        </div>
        <div
          :for={day <- @days}
          id={"#{@id}-day-#{Date.to_iso8601(day)}"}
          role="gridcell"
          tabindex={tab_index(day == @focus)}
          data-date={Date.to_iso8601(day)}
          aria-selected={to_string(day == @selected)}
          aria-current={day == @today && "date"}
          aria-label={cell_label(@cell_label, day, Map.get(@by_day, day, []))}
          phx-click={@select_event}
          phx-target={@target}
          phx-value-date={Date.to_iso8601(day)}
          class="calendar-hours-day"
        >
          <span
            :for={placed <- Layout.place(Map.get(@by_day, day, []), @hours)}
            data-event={placed.event.id}
            style={box_style(placed)}
            class={[
              "calendar-hours-event",
              surface(placed.event.kind),
              text(placed.event.kind),
              accent(placed.event.kind)
            ]}
          >
            <strong class="block truncate font-semibold">{placed.event.label}</strong>
            <span :if={Map.get(placed.event, :detail)} class="block truncate">
              {placed.event.detail}
            </span>
          </span>
        </div>
      </div>
    </.grid>
    """
  end

  defp hours_days(%{weekend: true, weekdays: weekdays, weeks: [week]}),
    do: Enum.zip(weekdays, week)

  defp hours_days(%{weekdays: weekdays, weeks: [week]}),
    do: weekdays |> Enum.zip(week) |> Enum.filter(&workday?/1)

  defp workday?({_name, day}), do: Date.day_of_week(day) in 1..5

  defp all_day_events(by_day, day),
    do: by_day |> Map.get(day, []) |> Enum.reject(&Map.has_key?(&1, :starts_at))

  defp box_style(%{top: top, height: height, left: left, width: width}),
    do:
      "top: #{top}%; height: #{height}%; left: calc(#{left}% + 2px); width: calc(#{width}% - 4px)"

  defp hour_label(nil, hour),
    do: "#{hour |> Integer.to_string() |> String.pad_leading(2, "0")}:00"

  defp hour_label(fun, hour), do: fun.(hour)

  defp surface(:chart_1), do: "border-chart-1 bg-chart-1/10"
  defp surface(:chart_2), do: "border-chart-2 bg-chart-2/10"
  defp surface(:chart_3), do: "border-chart-3 bg-chart-3/10"
  defp surface(:chart_4), do: "border-chart-4 bg-chart-4/10"
  defp surface(kind), do: Tone.surface(kind)

  defp text(kind) when kind in [:chart_1, :chart_2, :chart_3, :chart_4], do: "text-ink"
  defp text(kind), do: Tone.text(kind)

  defp fill(:chart_1), do: "bg-chart-1"
  defp fill(:chart_2), do: "bg-chart-2"
  defp fill(:chart_3), do: "bg-chart-3"
  defp fill(:chart_4), do: "bg-chart-4"
  defp fill(kind), do: Tone.fill(kind)

  defp accent(:chart_1), do: "border-l-chart-1!"
  defp accent(:chart_2), do: "border-l-chart-2!"
  defp accent(:chart_3), do: "border-l-chart-3!"
  defp accent(:chart_4), do: "border-l-chart-4!"
  defp accent(:risk), do: "border-l-missing!"
  defp accent(:warn), do: "border-l-ai!"
  defp accent(:ok), do: "border-l-tag-ok-text!"
  defp accent(:info), do: "border-l-learn!"
  defp accent(:neutral), do: "border-l-ink!"

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

  defp shown(_by_day, day, :month, %Date{month: month}) when day.month != month, do: []
  defp shown(by_day, day, _view, _date), do: Map.get(by_day, day, [])

  defp cell_label(nil, day, events) do
    base = Calendar.strftime(day, "%d/%m/%Y")

    case events do
      [] -> base
      list -> "#{base}: #{Enum.map_join(list, ", ", & &1.label)}"
    end
  end

  defp cell_label(fun, day, events), do: fun.(day, events)
end
