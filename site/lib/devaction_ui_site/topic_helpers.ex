defmodule DevactionUISite.TopicHelpers do
  @moduledoc "The small functions some examples call: a calendar's title and the icon of a sidebar item."

  alias DevactionUI.Calendar

  @months ~w(January February March April May June July August September October November December)

  @doc "The title of a month or a week as the calendar examples write it."
  def calendar_title(date, :month),
    do: Elixir.Calendar.strftime(date, "%B %Y", month_names: &Enum.at(@months, &1 - 1))

  def calendar_title(date, :week), do: Calendar.title(date, :week)

  @doc "The icon of the demo sidebar's items."
  def sidebar_icon("Today"), do: "sparkles"
  def sidebar_icon("Projects"), do: "contracts"
  def sidebar_icon("Contracts"), do: "contracts"
  def sidebar_icon(_label), do: "git-pull-request"
end
