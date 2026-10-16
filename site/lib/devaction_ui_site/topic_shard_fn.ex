defmodule DevactionUISite.TopicShardFN do
  @moduledoc "The examples whose topic starts with f-n: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[f-n]*"]
end
