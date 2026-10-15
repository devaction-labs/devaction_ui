defmodule DevactionUI.Chart.Geometry do
  @moduledoc """
  The arithmetic of the charts, with no markup: where a value sits on an axis, the path of a line, an area, a
  column with a rounded top and a slice of a ring. Every function is pure, so the charts can be drawn on the
  server and tested without a browser.
  """

  @steps [1, 1.2, 1.6, 2, 2.4, 3, 4, 5, 6, 8, 10]

  @doc "A round number at or above `value`, to end an axis on, that four grid lines divide without a mess: 1, 1.2, 1.6, 2, 2.4, 3, 4, 5, 6, 8 or 10 times a power of ten."
  @spec nice_max(number()) :: number()
  def nice_max(value) when value <= 0, do: 1

  def nice_max(value) do
    magnitude = :math.pow(10, Float.floor(:math.log10(value)))
    step = Enum.find(@steps, &(&1 * magnitude >= value))
    round_to(step * magnitude)
  end

  @doc "`count + 1` evenly spaced values from 0 to `max`, for the grid lines."
  @spec ticks(number(), pos_integer()) :: [number()]
  def ticks(max, count), do: for(i <- 0..count, do: round_to(max * i / count))

  @doc "The `y` of `value` on an axis from 0 to `max` drawn between `bottom` and `top`."
  @spec scale(number(), number(), number(), number()) :: float()
  def scale(value, max, bottom, top), do: round_to(bottom - value / max * (bottom - top))

  @doc "`count` positions from `left` to `right`; one position is the middle."
  @spec spread(pos_integer(), number(), number()) :: [float()]
  def spread(0, _left, _right), do: []
  def spread(1, left, right), do: [round_to((left + right) / 2)]

  def spread(count, left, right),
    do: for(i <- 0..(count - 1)//1, do: round_to(left + i * (right - left) / (count - 1)))

  @doc "The path of a line through `{x, y}` points."
  @spec line_path([{number(), number()}]) :: String.t()
  def line_path([]), do: ""

  def line_path([{x, y} | rest]),
    do:
      Enum.join(
        ["M#{fmt(x)} #{fmt(y)}" | Enum.map(rest, fn {a, b} -> "L#{fmt(a)} #{fmt(b)}" end)],
        " "
      )

  @doc "The path of the area under a line, closed down to `baseline`."
  @spec area_path([{number(), number()}], number()) :: String.t()
  def area_path([], _baseline), do: ""

  def area_path(points, baseline) do
    {first_x, _} = List.first(points)
    {last_x, _} = List.last(points)
    "#{line_path(points)} L#{fmt(last_x)} #{fmt(baseline)} L#{fmt(first_x)} #{fmt(baseline)} Z"
  end

  @doc "A column from `baseline` up to `top`, `width` wide, with the top corners rounded by `radius`."
  @spec column_path(number(), number(), number(), number(), number()) :: String.t()
  def column_path(x, top, baseline, width, radius) do
    r = min(radius, min(width / 2, max(baseline - top, 0)))
    right = x + width

    "M#{fmt(x)} #{fmt(baseline)} L#{fmt(x)} #{fmt(top + r)} Q#{fmt(x)} #{fmt(top)} #{fmt(x + r)} #{fmt(top)} " <>
      "L#{fmt(right - r)} #{fmt(top)} Q#{fmt(right)} #{fmt(top)} #{fmt(right)} #{fmt(top + r)} L#{fmt(right)} #{fmt(baseline)} Z"
  end

  @doc """
  The slices of a ring from `values`: `{start, stop}` angles in degrees, from the top, clockwise, each one
  shortened by `gap` degrees so the slices do not touch. A value of 0 has no slice.
  """
  @spec slices([number()], number()) :: [{float(), float()} | nil]
  def slices(values, gap) do
    total = Enum.sum(values)

    {result, _} =
      Enum.map_reduce(values, 0.0, fn value, angle ->
        sweep = sweep_of(value, total)
        {slice(sweep, angle, gap), angle + sweep}
      end)

    result
  end

  defp sweep_of(_value, total) when total == 0, do: 0.0
  defp sweep_of(value, total), do: value / total * 360

  defp slice(sweep, _angle, _gap) when sweep == 0, do: nil
  defp slice(sweep, angle, gap), do: trim(angle, angle + sweep, gap, sweep)

  defp trim(start, stop, gap, sweep) when sweep > gap * 2, do: {start + gap / 2, stop - gap / 2}
  defp trim(start, stop, _gap, _sweep), do: {start, stop}

  @doc "The path of a ring slice between two radii, from angle `a` to `b` (degrees from the top, clockwise)."
  @spec arc_path(number(), number(), number(), number(), number(), number()) :: String.t()
  def arc_path(cx, cy, outer, inner, a, b) do
    {ox1, oy1} = point(cx, cy, outer, a)
    {ox2, oy2} = point(cx, cy, outer, b)
    {ix2, iy2} = point(cx, cy, inner, b)
    {ix1, iy1} = point(cx, cy, inner, a)
    large = large_flag(b - a)

    "M#{fmt(ox1)} #{fmt(oy1)} A#{fmt(outer)} #{fmt(outer)} 0 #{large} 1 #{fmt(ox2)} #{fmt(oy2)} " <>
      "L#{fmt(ix2)} #{fmt(iy2)} A#{fmt(inner)} #{fmt(inner)} 0 #{large} 0 #{fmt(ix1)} #{fmt(iy1)} Z"
  end

  defp large_flag(sweep) when sweep > 180, do: 1
  defp large_flag(_sweep), do: 0

  @doc "The point at `angle` degrees from the top, clockwise, on a circle."
  @spec point(number(), number(), number(), number()) :: {float(), float()}
  def point(cx, cy, radius, angle) do
    radians = angle * :math.pi() / 180
    {round_to(cx + radius * :math.sin(radians)), round_to(cy - radius * :math.cos(radians))}
  end

  @doc "A number as the least text that says it: `12`, `12.5`."
  @spec fmt(number()) :: String.t()
  def fmt(value) when is_integer(value), do: Integer.to_string(value)

  def fmt(value) do
    rounded = round_to(value)
    text(rounded, rounded == trunc(rounded))
  end

  defp text(rounded, true), do: Integer.to_string(trunc(rounded))
  defp text(rounded, false), do: Float.to_string(rounded)

  @doc "A number rounded to two decimals, so paths stay short."
  @spec round_to(number()) :: float() | integer()
  def round_to(value) when is_integer(value), do: value

  def round_to(value) do
    rounded = Float.round(value * 1.0, 2)
    whole(rounded, rounded == Float.floor(rounded))
  end

  defp whole(rounded, true), do: trunc(rounded)
  defp whole(rounded, false), do: rounded

  defp place(previous, y, gap) when is_number(previous) and y < previous + gap, do: previous + gap
  defp place(_previous, y, _gap), do: y

  @doc "Moves labels apart: `ys` are positions, the result keeps the order and leaves `gap` between neighbours."
  @spec separate([number()], number()) :: [number()]
  def separate(ys, gap) do
    ys
    |> Enum.with_index()
    |> Enum.sort_by(fn {y, _index} -> y end)
    |> Enum.map_reduce(nil, fn {y, index}, previous ->
      placed = place(previous, y, gap)
      {{index, placed}, placed}
    end)
    |> elem(0)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end
end
