defmodule :"Elixir.DevopsInsights.Repo.Migrations.Remove type from deployment events" do
  use Ecto.Migration

  def change do
    alter table("events") do
      remove :type
    end
  end
end
