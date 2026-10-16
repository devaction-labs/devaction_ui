defmodule DevactionUISite.Changelog.Entry do
  @moduledoc "One line of a release: what kind of change it is, the group and name of the component, and a sentence."
  use Ecto.Schema

  alias DevactionUISite.Changelog.Version

  @kinds ~w(new improved fixed breaking planned)

  schema "changelog_entries" do
    field(:kind, :string)
    field(:group, :string)
    field(:name, :string)
    field(:summary, :string)
    field(:position, :integer)

    belongs_to(:version, Version)

    timestamps(type: :utc_datetime)
  end

  @doc "The kinds of change an entry can be."
  def kinds, do: @kinds
end
