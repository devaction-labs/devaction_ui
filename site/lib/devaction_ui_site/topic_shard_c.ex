defmodule DevactionUISite.TopicShardC do
  @moduledoc "The examples whose topic starts with : see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/c*"]
end
