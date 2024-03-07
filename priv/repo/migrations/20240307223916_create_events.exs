defmodule DevopsInsights.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :type, :string
      add :timestamp, :utc_datetime
      add :serviceName, :string
      add :environmnet, :string

      timestamps(type: :utc_datetime)
    end
  end
end
