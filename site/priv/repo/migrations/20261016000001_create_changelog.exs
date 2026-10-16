defmodule DevactionUISite.Repo.Migrations.CreateChangelog do
  use Ecto.Migration

  def change do
    create table(:changelog_versions) do
      add :version, :string, null: false
      add :status, :string, null: false
      add :tag, :string
      add :released_on, :date
      add :summary, :text, null: false
      add :position, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:changelog_versions, [:version])

    create table(:changelog_entries) do
      add :version_id, references(:changelog_versions, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :group, :string, null: false
      add :name, :string, null: false
      add :summary, :text, null: false
      add :position, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:changelog_entries, [:version_id])
    create unique_index(:changelog_entries, [:version_id, :group, :name])
  end
end
