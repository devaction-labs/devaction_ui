defmodule DevactionUISite.TopicShardAB do
  @moduledoc "The examples whose topic starts with a-b: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[a-b]*"]
end
