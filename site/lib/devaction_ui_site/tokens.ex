defmodule DevactionUISite.Tokens do
  @moduledoc """
  The colour tokens of `assets/css/devaction_ui.css`, read from the stylesheet itself so the page can never
  show a colour the library does not ship. Each is a `light-dark(#light, #dark)` pair.
  """

  @css Path.expand("../../../assets/css/devaction_ui.css", __DIR__)
  @external_resource @css

  @pattern ~r/^\s*--([a-z0-9-]+):\s*light-dark\((#[0-9A-Fa-f]{6}),\s*(#[0-9A-Fa-f]{6})\);/m
  @tokens Regex.scan(@pattern, File.read!(@css))
          |> Enum.map(fn [_line, name, light, dark] ->
            %{name: name, light: light, dark: dark}
          end)

  @order ["Surfaces", "Lines", "Text", "Accents", "Tags", "Charts"]

  @doc "The tokens grouped for display, in a fixed order."
  def groups do
    by_group = Enum.group_by(@tokens, &group/1)
    for name <- @order, tokens = Map.get(by_group, name), do: {name, tokens}
  end

  @doc "How many tokens the stylesheet declares."
  def count, do: length(@tokens)

  defp group(%{name: "tag-" <> _}), do: "Tags"
  defp group(%{name: "chart-" <> _}), do: "Charts"
  defp group(%{name: "line" <> _}), do: "Lines"
  defp group(%{name: name}) when name in ~w(frame panel wrap card), do: "Surfaces"
  defp group(%{name: name}) when name in ~w(ink ink-2 muted muted-2 on-primary), do: "Text"
  defp group(_token), do: "Accents"
end
