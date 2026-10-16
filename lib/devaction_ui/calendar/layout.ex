defmodule DevactionUI.Calendar.Layout do
  @moduledoc """
  Where the events of one day go in a column of hours: the pure geometry behind the week view with hours.

  An event is a map with `starts_at` and, optionally, `ends_at` (both `Time`). One without `ends_at` lasts
  30 minutes and one that ends before it starts lasts 15. Events that overlap in time share the width of
  the column: each gets a column of its own (`left` and `width`, as percentages of the day) and the
  ones that do not touch keep the full width. `top` and `height` are percentages of the hours shown, so the
  caller needs to know no pixel size. An event that crosses the edge of the range is cut at the edge, one fully
  outside it is not placed, and one without `starts_at` is not placed either (it is an all-day event).
  """

  @default_minutes 30
  @min_minutes 15

  @type placed :: %{
          event: map(),
          top: float(),
          height: float(),
          left: float(),
          width: float()
        }

  @doc "The events of a day placed in the column of the hours in `hours` (a range such as `8..17`, the last hour included)."
  @spec place([map()], Range.t()) :: [placed()]
  def place(events, hours) do
    first = hours.first * 60
    last = (hours.last + 1) * 60

    events
    |> Enum.flat_map(&span(&1, first, last))
    |> Enum.sort_by(fn {_event, from, to} -> {from, -to} end)
    |> Enum.reduce([], &join/2)
    |> Enum.reverse()
    |> Enum.flat_map(fn {group, _reach} -> group |> Enum.reverse() |> columns() end)
    |> Enum.map(&box(&1, first, last - first))
  end

  @doc "The minutes since midnight of a time."
  @spec minutes(Time.t()) :: non_neg_integer()
  def minutes(%Time{hour: hour, minute: minute}), do: hour * 60 + minute

  defp span(%{starts_at: %Time{} = starts_at} = event, first, last) do
    from = minutes(starts_at)
    clip(event, max(from, first), min(finish(event, from), last))
  end

  defp span(_event, _first, _last), do: []

  defp finish(%{ends_at: %Time{} = ends_at}, from), do: max(minutes(ends_at), from + @min_minutes)
  defp finish(_event, from), do: from + @default_minutes

  defp clip(event, from, to) when to > from, do: [{event, from, to}]
  defp clip(_event, _from, _to), do: []

  defp join({_event, from, to} = span, [{group, reach} | done]) when from < reach,
    do: [{[span | group], max(reach, to)} | done]

  defp join({_event, _from, to} = span, done), do: [{[span], to} | done]

  defp columns(group) do
    {placed, ends} = Enum.map_reduce(group, [], &assign/2)
    Enum.map(placed, fn {event, from, to, column} -> {event, from, to, column, length(ends)} end)
  end

  defp assign({event, from, to}, ends) do
    case Enum.find_index(ends, &(&1 <= from)) do
      nil -> {{event, from, to, length(ends)}, ends ++ [to]}
      column -> {{event, from, to, column}, List.replace_at(ends, column, to)}
    end
  end

  defp box({event, from, to, column, count}, first, total) do
    %{
      event: event,
      top: percent(from - first, total),
      height: percent(to - from, total),
      left: percent(column, count),
      width: percent(1, count)
    }
  end

  defp percent(part, whole), do: Float.round(part / whole * 100, 3)
end
