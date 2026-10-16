defmodule DevactionUISite.TopicShardRS do
  @moduledoc "The examples whose topic starts with r-s: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[r-s]*"]
end
