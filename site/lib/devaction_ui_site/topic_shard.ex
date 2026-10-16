defmodule DevactionUISite.TopicShard do
  @moduledoc """
  One slice of the examples of the documentation: `use` it with the patterns of the files it holds. Compiling
  the templates in several modules, in files of their own, lets the compiler do them in parallel instead of
  one after the other inside a single module.
  """
  defmacro __using__(patterns) do
    quote bind_quoted: [patterns: patterns] do
      use DevactionUISite.UI

      import DevactionUISite.TopicHelpers

      for pattern <- patterns, do: embed_templates(pattern)
    end
  end
end
