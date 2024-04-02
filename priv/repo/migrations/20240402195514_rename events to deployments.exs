defmodule :"Elixir.DevopsInsights.Repo.Migrations.Rename events to deployments" do
  use Ecto.Migration

  def change do
    rename table("events"), to: table("deployments")
    execute "ALTER INDEX IF EXISTS events_pkey RENAME TO deployments_pkey"
  end
end
