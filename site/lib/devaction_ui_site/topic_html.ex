defmodule DevactionUISite.TopicHTML do
  @moduledoc """
  The live examples of every topic. Each is one template in `examples/`, named `<topic>_<nn>.html.heex`, whose
  first line is a HEEx comment with its title and a short text. `render/2` draws one with the page's assigns,
  and `for_topic/1` lists a topic's examples with the text of each, which the page shows under the preview.
  """
  use DevactionUISite.UI

  @header ~r/\A<%!-- title: (?<title>.*?) \| text: (?<text>.*?)(?: \| layout: (?<layout>\w+))? --%>\n/

  @paths Path.wildcard(Path.join(__DIR__, "examples/*.html.heex"))
  for path <- @paths, do: @external_resource(path)

  @examples (for path <- @paths do
               base = path |> Path.basename() |> String.replace_suffix(".html.heex", "")

               %{"slug" => slug, "number" => number} =
                 Regex.named_captures(~r/\A(?<slug>.+)_(?<number>\d+)\z/, base)

               content = File.read!(path)

               %{"title" => title, "text" => text, "layout" => layout} =
                 Regex.named_captures(@header, content)

               %{
                 id: "#{slug}-#{number}",
                 slug: slug,
                 title: title,
                 text: text,
                 center?: layout == "center",
                 source: content |> String.replace(@header, "") |> String.trim_trailing(),
                 render: :"#{base}"
               }
             end)
            |> Enum.sort_by(& &1.id)

  embed_templates "examples/*"

  for %{id: id, render: render} <- @examples do
    def render(unquote(id), assigns), do: unquote(render)(assigns)
  end

  @doc "The examples of a topic in order."
  def for_topic(slug), do: Enum.filter(@examples, &(&1.slug == slug))

  @months ~w(January February March April May June July August September October November December)

  defp calendar_title(date, :month),
    do: Elixir.Calendar.strftime(date, "%B %Y", month_names: &Enum.at(@months, &1 - 1))

  defp calendar_title(date, :week), do: Calendar.title(date, :week)

  defp sidebar_icon("Today"), do: "sparkles"
  defp sidebar_icon("Projects"), do: "contracts"
  defp sidebar_icon("Contracts"), do: "contracts"
  defp sidebar_icon(_label), do: "git-pull-request"
end
