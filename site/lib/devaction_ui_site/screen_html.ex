defmodule DevactionUISite.ScreenHTML do
  @moduledoc """
  The templates of `Templates`, one per file in `screens/`, named `<group>_<slug>.html.heex`. `render/2` draws a
  screen with the assigns of its LiveView and `source/2` gives the text of its template, which the documentation
  shows beside the preview.
  """
  use DevactionUISite.UI

  alias DevactionUISite.TemplateData

  @paths Path.wildcard(Path.join(__DIR__, "screens/*.html.heex"))
  for path <- @paths, do: @external_resource(path)

  @sources Map.new(@paths, fn path ->
             {path |> Path.basename() |> String.replace_suffix(".html.heex", ""),
              File.read!(path)}
           end)

  embed_templates "screens/*"

  for key <- Map.keys(@sources) do
    def render(unquote(key), assigns), do: unquote(:"#{key}")(assigns)
  end

  def render(_key, assigns), do: ~H""

  @doc "The text of the template of a screen, or `nil`."
  def source(group, slug), do: Map.get(@sources, "#{group}_#{slug}")
end
