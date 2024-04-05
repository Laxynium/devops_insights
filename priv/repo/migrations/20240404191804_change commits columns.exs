defmodule :"Elixir.DevopsInsights.Repo.Migrations.Change commits columns" do
  use Ecto.Migration

  def change do
    alter table(:commits) do
      remove :properties, :map
      add :service_name, :string
    end
  end
end
