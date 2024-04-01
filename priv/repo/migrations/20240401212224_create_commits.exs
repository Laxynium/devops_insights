defmodule DevopsInsights.Repo.Migrations.CreateCommits do
  use Ecto.Migration

  def change do
    create table(:commits) do
      add :timestamp, :utc_datetime
      add :commit_id, :string
      add :parent_id, :string
      add :properties, :map

      timestamps(type: :utc_datetime)
    end
  end
end
