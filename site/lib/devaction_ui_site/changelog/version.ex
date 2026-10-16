defmodule DevactionUISite.Changelog.Version do
  @moduledoc "A release of the kit (or the next one) and the entries that came with it."
  use Ecto.Schema

  alias DevactionUISite.Changelog.Entry

  @statuses ~w(current next archived)

  schema "changelog_versions" do
    field(:version, :string)
    field(:status, :string)
    field(:tag, :string)
    field(:released_on, :date)
    field(:summary, :string)
    field(:position, :integer)

    has_many(:entries, Entry)

    timestamps(type: :utc_datetime)
  end

  @doc "The statuses a version can have."
  def statuses, do: @statuses
end
