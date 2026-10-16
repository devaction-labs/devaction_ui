defmodule DevactionUISite.TopicShardDE do
  @moduledoc "The examples whose topic starts with d-e: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[d-e]*"]
end
