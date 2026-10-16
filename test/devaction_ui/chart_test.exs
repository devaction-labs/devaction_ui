defmodule DevactionUI.ChartTest do
  @moduledoc "The charts: the arithmetic behind them and what each one draws and says."
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias DevactionUI.Chart
  alias DevactionUI.Chart.Geometry

  describe "Geometry" do
    test "an axis ends on a round number" do
      assert Geometry.nice_max(110) == 120
      assert Geometry.nice_max(104) == 120
      assert Geometry.nice_max(9) == 10
      assert Geometry.nice_max(0.07) == 0.08
      assert Geometry.nice_max(0) == 1
      assert Geometry.nice_max(-4) == 1
      assert Geometry.nice_max(1000) == 1000
    end

    test "the ticks are whole numbers when they can be" do
      assert Geometry.ticks(200, 4) == [0, 50, 100, 150, 200]
      assert Geometry.ticks(1, 2) == [0, 0.5, 1]
    end

    test "a value sits between the baseline and the top" do
      assert Geometry.scale(0, 100, 250, 16) == 250
      assert Geometry.scale(100, 100, 250, 16) == 16
      assert Geometry.scale(50, 100, 250, 16) == 133
    end

    test "points are spread across the width and one is in the middle" do
      assert Geometry.spread(3, 0, 100) == [0, 50, 100]
      assert Geometry.spread(1, 0, 100) == [50]
      assert Geometry.spread(0, 0, 100) == []
    end

    test "a line, an area and a column are paths" do
      assert Geometry.line_path([]) == ""
      assert Geometry.line_path([{1, 2}, {3.5, 4}]) == "M1 2 L3.5 4"
      assert Geometry.area_path([], 9) == ""
      assert Geometry.area_path([{0, 5}, {10, 3}], 20) == "M0 5 L10 3 L10 20 L0 20 Z"

      column = Geometry.column_path(10, 20, 100, 24, 4)
      assert column =~ "Q10 20 14 20"
      assert String.starts_with?(column, "M10 100 L10 24")
      assert Geometry.column_path(10, 99, 100, 24, 4) =~ "Q10 99 11 99"
      assert Geometry.column_path(10, 100, 100, 24, 4) =~ "L10 100"
    end

    test "the slices of a ring add up to a circle, leave a gap and skip a zero" do
      assert [{1.25, 178.75}, {181.25, 358.75}] = Geometry.slices([1, 1], 2.5)
      assert [{_, _}, nil] = Geometry.slices([5, 0], 2.5)
      assert [nil, nil] = Geometry.slices([0, 0], 2.5)
      assert [{0.0, 3.6}] = Geometry.slices([1], 0) |> Enum.map(fn {a, _} -> {a, 3.6} end)

      [{start, stop}, small] = Geometry.slices([99, 1], 2.5)
      assert stop - start > 350
      assert {_, _} = small
      {s, e} = small
      assert_in_delta e - s, 3.6, 0.01
    end

    test "a slice is an arc between two radii" do
      path = Geometry.arc_path(80, 80, 76, 52, 0, 90)
      assert path =~ "A76 76 0 0 1"
      assert path =~ "A52 52 0 0 0"
      assert Geometry.arc_path(80, 80, 76, 52, 0, 270) =~ "0 1 1"
      assert Geometry.point(80, 80, 10, 0) == {80, 70}
      assert Geometry.point(80, 80, 10, 90) == {90, 80}
    end

    test "labels are moved apart without changing their order" do
      assert Geometry.separate([100, 103], 14) == [100, 114]
      assert Geometry.separate([103, 100], 14) == [114, 100]
      assert Geometry.separate([10, 100], 14) == [10, 100]
      assert Geometry.separate([], 14) == []
    end

    test "numbers are written with as few digits as they need" do
      assert Geometry.fmt(12) == "12"
      assert Geometry.fmt(12.0) == "12"
      assert Geometry.fmt(12.456) == "12.46"
      assert Geometry.round_to(3) == 3
      assert Geometry.round_to(2.5) == 2.5
    end
  end

  describe "line_chart" do
    defp line(extra \\ %{}) do
      assigns =
        Map.merge(
          %{
            table?: false,
            labels: ~w(Mar Apr May),
            series: [
              %{label: "Done", values: [10, 20, 30]},
              %{label: "Forecast", values: [12, 18, 33]}
            ]
          },
          extra
        )

      rendered_to_string(~H"""
      <Chart.line_chart
        id="c"
        summary="Revenue"
        labels={@labels}
        series={@series}
        table?={@table?}
        first_column="MONTH"
        format={&"#{&1}k"}
      />
      """)
    end

    test "is a group with a summary, a legend, the axis, the area and two solid lines" do
      html = line()

      assert html =~ ~s(<svg viewBox="0 0 820 280" role="group")
      refute html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Revenue")
      assert html =~ "chart-legend"
      assert html =~ "Done" and html =~ "Forecast"
      assert html =~ "chart-area"
      assert length(Regex.scan(~r/chart-line/, html)) == 2
      refute html =~ "stroke-dasharray"
      refute html =~ "mask-image"
      assert html =~ "stroke-chart-1" and html =~ "stroke-chart-2"
      assert html =~ "40k"
      assert html =~ ">Mar<"
    end

    test "a series can be dashed, with a dashed key in the legend" do
      html =
        line(%{
          series: [
            %{label: "Done", values: [10, 20, 30]},
            %{label: "Forecast", values: [12, 18, 33], dashed: true}
          ]
        })

      assert length(Regex.scan(~r/stroke-dasharray="6 5"/, html)) == 1

      assert html =~
               ~r/stroke-dasharray="6 5"[^>]*stroke-chart-2|stroke-chart-2[^>]*stroke-dasharray/s

      assert length(Regex.scan(~r/mask-image/, html)) == 1
    end

    test "the grid and the line follow the canvas: grid from 44 to 800, points from 64 to 760" do
      html = line()

      assert html =~ ~s(x1="44" x2="800")
      assert html =~ ~s(x="36")
      assert html =~ ~s(<text x="64" y="270")
      assert html =~ ~s(<text x="760" y="270")
      assert html =~ ~s(<circle cx="760")
      assert html =~ ~s(<text x="770")
    end

    test "the axis of the days is sans, only the last value of the first line is bold" do
      html = line()

      assert html =~ ~r/class="chart-axis-x">\s*Mar/
      assert html =~ "fill-ink text-xs font-semibold"
      assert html =~ ~s(class="fill-ink-2 text-xs")
    end

    test "the hover layer is hidden from assistive technology, the column group names it" do
      html = line()

      assert html =~ ~r/aria-hidden="true"[^>]*class="opacity-0 transition-opacity/
      assert html =~ ~s(aria-label="Mar: Done 10k, Forecast 12k")
    end

    test "a chart with nothing to draw still shows its axes" do
      html = line(%{labels: [], series: []})

      assert html =~ "chart-grid"
      refute html =~ "chart-line"
    end

    test "each column can be reached with the keyboard and says its values" do
      html = line()

      assert length(Regex.scan(~r/tabindex="0"/, html)) == 3
      assert html =~ ~s(aria-label="Apr: Done 20k, Forecast 18k")
      assert html =~ "group-focus/col:opacity-100"
      assert html =~ "group-hover/col:opacity-100"
      assert html =~ ~s(role="status")
    end

    test "the end of each line carries its value and the labels do not overlap" do
      html =
        line(%{series: [%{label: "A", values: [1, 2, 30]}, %{label: "B", values: [1, 2, 30]}]})

      [first, second] =
        Regex.scan(
          ~r/<text x="[\d.]+" y="([\d.]+)" dy="4" class="[^"]*fill-ink[^"]*">\s*30k/,
          html,
          capture: :all_but_first
        )

      parse = &(&1 |> Float.parse() |> elem(0))
      assert abs(parse.(hd(first)) - parse.(hd(second))) >= 14
    end

    test "can show the table of the same data instead" do
      html = line(%{table?: true})

      assert html =~ "<table"
      assert html =~ "MONTH"
      assert html =~ ~s(scope="col")
      assert html =~ ~s(scope="row")
      assert html =~ "33k"
      refute html =~ "<svg"
    end

    test "draws with one point and with none" do
      assert line(%{labels: ["Mar"], series: [%{label: "A", values: [5]}]}) =~ "chart-line"
      assert line(%{labels: [], series: [%{label: "A", values: []}]}) =~ "<svg"
    end
  end

  describe "bars, columns, ring and sparkline" do
    test "bars show the value at the tip and are named for assistive technology" do
      assigns = %{items: [%{label: "SGE", value: 120}, %{label: "Hub", value: 40}]}

      html =
        rendered_to_string(
          ~H|<Chart.bar_chart id="b" summary="Hours" items={@items} format={&"#{&1} h"} />|
        )

      assert html =~ ~s(aria-label="Hours")
      assert html =~ "120 h" and html =~ "40 h"
      assert html =~ "calc((100% - 4rem) * 100 / 100)"
      assert html =~ "calc((100% - 4rem) * 33.33 / 100)"
      assert html =~ "rounded-r-[4px]"
      assert html =~ "h-5"
      refute html =~ ~s(role="img")
      assert length(Regex.scan(~r/tabindex="0"/, html)) == 2
      assert html =~ ~s(aria-label="SGE: 120 h")
      assert html =~ "group-has-[[data-item]:hover]/dim:not-hover:opacity-40"
    end

    test "columns are at most 24 wide, with a rounded top and the value shown only on the column in focus" do
      assigns = %{items: [%{label: "W1", value: 4}, %{label: "W2", value: 9}]}
      html = rendered_to_string(~H|<Chart.column_chart id="c" summary="PRs" items={@items} />|)

      assert length(Regex.scan(~r/fill-chart-1/, html)) == 2
      assert html =~ ">W1<"
      assert html =~ ~r/>\s*9\s*</
      assert html =~ "Q"
      assert html =~ "opacity-0"
      assert html =~ "group-hover/col:opacity-100"
      assert html =~ "group-focus/col:opacity-100"
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="W2: 9")
      assert length(Regex.scan(~r/tabindex="0"/, html)) == 2
      assert html =~ "group-has-[[data-item]:focus-visible]/dim:not-focus-visible:opacity-40"
    end

    test "bars, columns and ring with nothing to draw show no part and do not break" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Chart.bar_chart id="b" summary="S" items={[]} />
        <Chart.column_chart id="c" summary="S" items={[]} />
        <Chart.donut_chart id="d" summary="S" items={[]} />
        """)

      refute html =~ "data-item"
      refute html =~ ~r/<li[ >]/
      assert html =~ "chart-grid"
    end

    test "columns follow the canvas: a 220 high box, grid from 40 to 800, columns from 80 to 780" do
      assigns = %{items: [%{label: "W1", value: 4}, %{label: "W2", value: 9}]}
      html = rendered_to_string(~H|<Chart.column_chart id="c" summary="PRs" items={@items} />|)

      assert html =~ ~s(viewBox="0 0 820 220")
      assert html =~ ~s(x1="40" x2="800")
      assert html =~ ~s(<text x="80" y="210")
      assert html =~ ~s(<text x="780" y="210")
      assert html =~ "text-xs font-semibold opacity-0"
    end

    test "the ring has a slice per value, a legend with the figures and the percentage, and the total in the hole" do
      assigns = %{
        items: [
          %{label: "Approved", value: 18},
          %{label: "No PR", value: 0},
          %{label: "Review", value: 8}
        ]
      }

      html =
        rendered_to_string(~H"""
        <Chart.donut_chart id="d" summary="Scope" items={@items}>
          <:center>26</:center>
        </Chart.donut_chart>
        """)

      assert length(Regex.scan(~r/<path/, html)) == 2
      assert html =~ ~s(viewBox="0 0 220 220")
      assert html =~ ~s(width="220")
      assert html =~ "chart-slice"
      assert html =~ "aria-label=\"Approved: 18 (69%)\""
      assert length(Regex.scan(~r/tabindex="0"/, html)) == 2
      assert html =~ "rounded-[3px]"
      assert html =~ "group-has-[[data-item]:hover]/dim:not-hover:opacity-35"
      assert html =~ "69%" and html =~ "31%" and html =~ "0%"
      assert html =~ "Approved"
      assert html =~ ~r/>\s*26\s*</
      assert html =~ "bg-chart-3"

      empty =
        rendered_to_string(
          ~H|<Chart.donut_chart id="d" summary="S" items={[%{label: "A", value: 0}]} />|
        )

      refute empty =~ "<path"
      assert empty =~ "0%"
    end

    test "the sparkline is a small image with the end marked" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Chart.sparkline summary="Trend" values={[3, 5, 4, 8]} id="s" />|)

      assert html =~ ~s(aria-label="Trend")
      assert html =~ ~s(role="img")
      assert html =~ "chart-area-spark"
      assert html =~ "<circle"

      assert rendered_to_string(~H|<Chart.sparkline summary="x" values={[]} />|) =~ "<svg"
      assert rendered_to_string(~H|<Chart.sparkline summary="x" values={[7]} />|) =~ "<circle"
    end

    test "the ring has a size" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Chart.donut_chart id="d" summary="S" size={160} items={[%{label: "A", value: 1}]} />|
        )

      assert html =~ ~s(width="160")
      assert html =~ "width: 160px"
    end

    test "a chart with nothing in it still draws, without a slice, a bar or a column" do
      assigns = %{}

      assert rendered_to_string(~H|<Chart.bar_chart id="b" summary="S" items={[]} />|) =~ "<ul"

      columns = rendered_to_string(~H|<Chart.column_chart id="c" summary="S" items={[]} />|)
      assert columns =~ "<svg"
      refute columns =~ "tabindex"

      ring = rendered_to_string(~H|<Chart.donut_chart id="d" summary="S" items={[]} />|)
      refute ring =~ "<path"
      refute ring =~ "tabindex"

      assert line(%{labels: [], series: []}) =~ "<svg"
    end

    test "the palette is fixed, four colours, and wraps" do
      assert Chart.stroke(0) == "stroke-chart-1"
      assert Chart.fill(3) == "fill-chart-4"
      assert Chart.bg(4) == "bg-chart-1"
      assert Chart.text(nil, 3) == "3"
      assert Chart.text(&"#{&1}%", 3) == "3%"
    end
  end
end
