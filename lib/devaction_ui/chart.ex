defmodule DevactionUI.Chart do
  @moduledoc """
  Light charts in plain SVG, drawn on the server: a line with two series, horizontal bars, columns, a ring and
  the sparkline of a number card. No library and no script: the hover is CSS (and keyboard focus shows the same).

  The series take the fixed palette `chart-1` to `chart-4` (blue, amber, teal, purple). Colour is never the only
  way to tell a series: there is always a legend, the second line is dashed, the end of each line carries its value
  and the line chart has a table view (`table?`; the caller owns the toggle). Every chart is an `img` with a
  summary for assistive technology.
  """
  use Phoenix.Component

  alias DevactionUI.Chart.Geometry

  @stroke ~w(stroke-chart-1 stroke-chart-2 stroke-chart-3 stroke-chart-4)
  @fill ~w(fill-chart-1 fill-chart-2 fill-chart-3 fill-chart-4)
  @bg ~w(bg-chart-1 bg-chart-2 bg-chart-3 bg-chart-4)

  @width 820
  @height 280
  @left 52
  @right 730
  @top 16
  @bottom 250

  @doc "The class that colours the stroke of series `index` (from 0)."
  @spec stroke(non_neg_integer()) :: String.t()
  def stroke(index), do: Enum.at(@stroke, rem(index, 4))

  @doc "The class that fills with the colour of series `index` (from 0)."
  @spec fill(non_neg_integer()) :: String.t()
  def fill(index), do: Enum.at(@fill, rem(index, 4))

  @doc "The class that sets the background to the colour of series `index` (from 0)."
  @spec bg(non_neg_integer()) :: String.t()
  def bg(index), do: Enum.at(@bg, rem(index, 4))

  attr :id, :string, required: true

  attr :summary, :string,
    required: true,
    doc: "what the chart shows, in a sentence, for assistive technology"

  attr :labels, :list, required: true, doc: "the text under each point of the horizontal axis"

  attr :series, :list,
    required: true,
    doc: "`%{label: text, values: [number]}` each; the first one gets the area"

  attr :format, :any,
    default: nil,
    doc: "number to text, for the axis, the ends and the tooltip"

  attr :table?, :boolean,
    default: false,
    doc: "shows the table of the same data instead of the chart"

  attr :first_column, :string, default: "", doc: "the head of the first column of the table"
  attr :class, :any, default: nil

  attr :rest, :global

  def line_chart(assigns) do
    max =
      assigns.series |> Enum.flat_map(& &1.values) |> Enum.max(fn -> 0 end) |> Geometry.nice_max()

    xs = Geometry.spread(length(assigns.labels), @left + 8, @right)

    lines =
      for {serie, index} <- Enum.with_index(assigns.series) do
        points = Enum.zip(xs, Enum.map(serie.values, &Geometry.scale(&1, max, @bottom, @top)))
        %{serie: serie, index: index, points: points}
      end

    lines = Enum.reject(lines, &(&1.points == []))

    ends =
      lines
      |> Enum.map(fn line -> line.points |> List.last() |> elem(1) end)
      |> Geometry.separate(14)

    lines =
      lines
      |> Enum.zip(ends)
      |> Enum.map(fn {line, label_y} -> Map.put(line, :label_y, label_y) end)

    assigns =
      assign(assigns,
        max: max,
        xs: xs,
        lines: lines,
        grid: Geometry.ticks(max, 4),
        width: @width,
        height: @height,
        left: @left,
        right: @right,
        top: @top,
        bottom: @bottom
      )

    ~H"""
    <div id={@id} class={["flex flex-col gap-3", @class]} {@rest}>
      <.legend series={@series} />
      <.data_table
        :if={@table?}
        labels={@labels}
        series={@series}
        format={@format}
        first_column={@first_column}
      />
      <svg
        :if={!@table?}
        viewBox={"0 0 #{@width} #{@height}"}
        role="img"
        aria-label={@summary}
        class="block h-auto w-full overflow-visible"
      >
        <g :for={tick <- @grid}>
          <line
            x1={@left}
            x2={@right + 10}
            y1={Geometry.scale(tick, @max, @bottom, @top)}
            y2={Geometry.scale(tick, @max, @bottom, @top)}
            class="chart-grid"
          />
          <text
            x={@left - 8}
            y={Geometry.scale(tick, @max, @bottom, @top)}
            dy="4"
            text-anchor="end"
            class="chart-axis"
          >
            {text(@format, tick)}
          </text>
        </g>
        <text
          :for={{label, x} <- Enum.zip(@labels, @xs)}
          x={x}
          y={@bottom + 20}
          text-anchor="middle"
          class="chart-axis"
        >
          {label}
        </text>
        <path
          :for={line <- Enum.take(@lines, 1)}
          d={Geometry.area_path(line.points, @bottom)}
          class={[fill(line.index), "chart-area"]}
        />
        <path
          :for={line <- Enum.reverse(@lines)}
          d={Geometry.line_path(line.points)}
          stroke-dasharray={dash(line.index)}
          class={["chart-line", stroke(line.index)]}
        />
        <g :for={line <- @lines}>
          <% {x, y} = List.last(line.points) %>
          <circle cx={x} cy={y} r="5" class={["chart-dot", fill(line.index)]} />
          <text
            x={x + 12}
            y={line.label_y}
            dy="4"
            class={["text-xs fill-ink", line.index > 0 && "fill-ink-2"]}
          >
            {text(@format, List.last(line.serie.values))}
          </text>
        </g>
        <g
          :for={{label, column} <- Enum.with_index(@labels)}
          tabindex="0"
          role="group"
          aria-label={tooltip_text(label, @series, column, @format)}
          class="group/col outline-none"
        >
          <rect
            x={Enum.at(@xs, column) - column_half(@xs)}
            y={@top - 6}
            width={column_half(@xs) * 2}
            height={@bottom - @top + 12}
            fill="transparent"
          />
          <g class="opacity-0 transition-opacity group-hover/col:opacity-100 group-focus/col:opacity-100 motion-reduce:transition-none">
            <line
              x1={Enum.at(@xs, column)}
              x2={Enum.at(@xs, column)}
              y1={@top}
              y2={@bottom}
              class="stroke-muted-2"
            />
            <circle
              :for={line <- @lines}
              cx={Enum.at(@xs, column)}
              cy={line.points |> Enum.at(column) |> elem(1)}
              r="5"
              class={["chart-dot", fill(line.index)]}
            />
            <.tooltip
              x={Enum.at(@xs, column)}
              title={label}
              rows={tooltip_rows(@series, column, @format)}
              width={@width}
            />
          </g>
        </g>
      </svg>
    </div>
    """
  end

  @doc "A number as text: through `format` when the caller gave one, as it is otherwise."
  @spec text((number() -> String.t()) | nil, number()) :: String.t()
  def text(nil, value), do: Geometry.fmt(value)
  def text(format, value), do: format.(value)

  defp column_half([_one]), do: 40
  defp column_half([a, b | _]), do: (b - a) / 2

  defp dash(0), do: nil
  defp dash(_index), do: "6 5"

  defp tooltip_rows(series, column, format),
    do:
      for(
        {serie, index} <- Enum.with_index(series),
        do: {index, serie.label, text(format, Enum.at(serie.values, column))}
      )

  defp tooltip_text(label, series, column, format) do
    rows = for {_i, name, value} <- tooltip_rows(series, column, format), do: "#{name} #{value}"
    "#{label}: #{Enum.join(rows, ", ")}"
  end

  attr :x, :any, required: true
  attr :title, :string, required: true
  attr :rows, :list, required: true
  attr :width, :integer, required: true

  defp tooltip(assigns) do
    height = 34 + length(assigns.rows) * 20
    left = assigns.x |> Kernel.-(90) |> max(0) |> min(assigns.width - 180)
    assigns = assign(assigns, height: height, left: left)

    ~H"""
    <g class="pointer-events-none" role="status">
      <rect x={@left} y="2" width="180" height={@height} rx="10" class="chart-tip-box" />
      <text x={@left + 12} y="22" class="fill-ink text-[13px] font-semibold">{@title}</text>
      <g :for={{{index, label, value}, row} <- Enum.with_index(@rows)}>
        <circle cx={@left + 16} cy={40 + row * 20} r="4" class={fill(index)} />
        <text x={@left + 28} y={44 + row * 20} class="fill-ink-2 text-[12px]">{label}</text>
        <text
          x={@left + 168}
          y={44 + row * 20}
          text-anchor="end"
          class="fill-ink font-mono text-[12px]"
        >
          {value}
        </text>
      </g>
    </g>
    """
  end

  attr :series, :list, required: true

  defp legend(assigns) do
    ~H"""
    <div class="chart-legend">
      <span :for={{serie, index} <- Enum.with_index(@series)} class="flex items-center gap-1.5">
        <span
          class={[
            "chart-key",
            bg(index),
            index > 0 &&
              "[mask-image:repeating-linear-gradient(90deg,#000_0_4px,transparent_4px_7px)]"
          ]}
          aria-hidden="true"
        />
        {serie.label}
      </span>
    </div>
    """
  end

  attr :labels, :list, required: true
  attr :series, :list, required: true
  attr :format, :any, required: true
  attr :first_column, :string, required: true

  defp data_table(assigns) do
    ~H"""
    <div class="overflow-x-auto rounded-xl border border-line">
      <table class="w-full border-collapse text-sm">
        <thead>
          <tr class="text-left font-mono text-[11px] tracking-[0.08em] text-muted">
            <th scope="col" class="border-b border-line px-3.5 py-2.5 font-medium">
              {@first_column}
            </th>
            <th
              :for={serie <- @series}
              scope="col"
              class="border-b border-line px-3.5 py-2.5 text-right font-medium"
            >
              {serie.label}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{label, row} <- Enum.with_index(@labels)}>
            <th scope="row" class="border-b border-line-soft px-3.5 py-2 text-left font-normal">
              {label}
            </th>
            <td
              :for={serie <- @series}
              class="border-b border-line-soft px-3.5 py-2 text-right font-mono"
            >
              {text(@format, Enum.at(serie.values, row))}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :summary, :string, required: true
  attr :items, :list, required: true, doc: "`%{label: text, value: number}` each"
  attr :format, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global

  def bar_chart(assigns) do
    max = assigns.items |> Enum.map(& &1.value) |> Enum.max(fn -> 0 end) |> Geometry.nice_max()
    assigns = assign(assigns, :max, max)

    ~H"""
    <ul
      id={@id}
      role="img"
      aria-label={@summary}
      class={["m-0 flex list-none flex-col gap-3 p-0", @class]}
      {@rest}
    >
      <li
        :for={item <- @items}
        class="grid grid-cols-[minmax(0,8rem)_1fr_auto] items-center gap-3 text-sm"
      >
        <span class="truncate text-ink-2">{item.label}</span>
        <span class="h-2 rounded-full bg-line-soft">
          <span
            class="block h-full rounded-full bg-chart-1"
            style={"width: #{Geometry.fmt(item.value / @max * 100)}%"}
          />
        </span>
        <span class="font-mono text-[13px] text-ink">{text(@format, item.value)}</span>
      </li>
    </ul>
    """
  end

  attr :id, :string, required: true
  attr :summary, :string, required: true
  attr :items, :list, required: true, doc: "`%{label: text, value: number}` each"
  attr :format, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global

  def column_chart(assigns) do
    max = assigns.items |> Enum.map(& &1.value) |> Enum.max(fn -> 0 end) |> Geometry.nice_max()
    xs = Geometry.spread(length(assigns.items), @left + 20, @right - 20)

    assigns =
      assign(assigns,
        max: max,
        xs: xs,
        width: @width,
        height: @height,
        bottom: @bottom,
        top: @top,
        left: @left,
        right: @right
      )

    ~H"""
    <svg
      id={@id}
      viewBox={"0 0 #{@width} #{@height}"}
      role="img"
      aria-label={@summary}
      class={["block h-auto w-full overflow-visible", @class]}
      {@rest}
    >
      <g :for={tick <- Geometry.ticks(@max, 4)}>
        <line
          x1={@left}
          x2={@right + 10}
          y1={Geometry.scale(tick, @max, @bottom, @top)}
          y2={Geometry.scale(tick, @max, @bottom, @top)}
          class="chart-grid"
        />
        <text
          x={@left - 8}
          y={Geometry.scale(tick, @max, @bottom, @top)}
          dy="4"
          text-anchor="end"
          class="chart-axis"
        >
          {text(@format, tick)}
        </text>
      </g>
      <g :for={{item, x} <- Enum.zip(@items, @xs)}>
        <path
          d={
            Geometry.column_path(
              x - 12,
              Geometry.scale(item.value, @max, @bottom, @top),
              @bottom,
              24,
              4
            )
          }
          class="fill-chart-1"
        />
        <text
          x={x}
          y={Geometry.scale(item.value, @max, @bottom, @top) - 8}
          text-anchor="middle"
          class="fill-ink font-mono text-xs"
        >
          {text(@format, item.value)}
        </text>
        <text x={x} y={@bottom + 20} text-anchor="middle" class="chart-axis">{item.label}</text>
      </g>
    </svg>
    """
  end

  attr :id, :string, required: true
  attr :summary, :string, required: true
  attr :items, :list, required: true, doc: "`%{label: text, value: number}` each"
  attr :format, :any, default: nil
  attr :class, :any, default: nil
  slot :center, doc: "what sits in the hole of the ring: the total"

  attr :rest, :global

  def donut_chart(assigns) do
    values = Enum.map(assigns.items, & &1.value)
    total = Enum.sum(values)
    slices = Geometry.slices(values, 2.5)

    assigns =
      assign(assigns,
        total: total,
        slices: Enum.zip([assigns.items, slices, Enum.with_index(assigns.items)])
      )

    ~H"""
    <div id={@id} class={["flex flex-wrap items-center gap-6", @class]} {@rest}>
      <div class="relative size-40 flex-none">
        <svg viewBox="0 0 160 160" role="img" aria-label={@summary} class="block size-full">
          <%= for {_item, slice, {_same, index}} <- @slices, slice do %>
            <path
              d={Geometry.arc_path(80, 80, 76, 52, elem(slice, 0), elem(slice, 1))}
              class={fill(index)}
            />
          <% end %>
        </svg>
        <span class="absolute inset-0 flex flex-col items-center justify-center text-center">
          {render_slot(@center)}
        </span>
      </div>
      <ul class="m-0 flex list-none flex-col gap-2 p-0 text-sm">
        <li :for={{item, _slice, {_same, index}} <- @slices} class="flex items-center gap-2.5">
          <span class={["size-2.5 rounded-sm", bg(index)]} aria-hidden="true" />
          <span class="text-ink-2">{item.label}</span>
          <span class="ml-auto pl-4 font-mono text-[13px] text-ink">{text(@format, item.value)}</span>
          <span class="w-10 text-right font-mono text-xs text-muted">{percent(item.value, @total)}</span>
        </li>
      </ul>
    </div>
    """
  end

  defp percent(_value, 0), do: "0%"
  defp percent(value, total), do: "#{round(value / total * 100)}%"

  attr :summary, :string, required: true
  attr :values, :list, required: true
  attr :width, :integer, default: 140
  attr :height, :integer, default: 48
  attr :class, :any, default: nil
  attr :rest, :global

  def sparkline(assigns) do
    max = assigns.values |> Enum.max(fn -> 0 end) |> max(1)
    min = assigns.values |> Enum.min(fn -> 0 end) |> min(max)
    span = max(max - min, 1)
    xs = Geometry.spread(max(length(assigns.values), 1), 6, assigns.width - 6)

    points =
      assigns.values
      |> Enum.zip(xs)
      |> Enum.map(fn {value, x} ->
        {x, Geometry.scale(value - min, span, assigns.height - 6, 6)}
      end)

    assigns = assign(assigns, points: points, last: List.last(points))

    ~H"""
    <svg
      width={@width}
      height={@height}
      viewBox={"0 0 #{@width} #{@height}"}
      role="img"
      aria-label={@summary}
      class={["flex-none", @class]}
      {@rest}
    >
      <path d={Geometry.area_path(@points, @height - 6)} class="fill-chart-1 chart-area" />
      <path d={Geometry.line_path(@points)} class="chart-line stroke-chart-1" />
      <circle
        :if={@last}
        cx={elem(@last, 0)}
        cy={elem(@last, 1)}
        r="4"
        class="chart-dot fill-chart-1"
      />
    </svg>
    """
  end
end
