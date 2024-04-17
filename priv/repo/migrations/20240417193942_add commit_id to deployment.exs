defmodule :"Elixir.DevopsInsights.Repo.Migrations.Add commitId to deployment" do
  use Ecto.Migration

  def change do
    alter table("deployments") do
      add :commit_id, :string, null: false
    end
  end
end
