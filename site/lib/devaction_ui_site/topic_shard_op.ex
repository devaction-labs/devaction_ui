defmodule DevactionUISite.TopicShardOP do
  @moduledoc "The examples whose topic starts with o-p: see `DevactionUISite.TopicShard`."
  use DevactionUISite.TopicShard, ["examples/[o-p]*"]
end
