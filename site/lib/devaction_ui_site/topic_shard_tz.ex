defmodule DevactionUISite.TopicShardTZ do
  @moduledoc "The examples whose topic starts with t-z: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[t-z]*"]
end
