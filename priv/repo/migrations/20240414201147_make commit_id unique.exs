defmodule :"Elixir.DevopsInsights.Repo.Migrations.Make commitId unique" do
  use Ecto.Migration

  def change do
    create_if_not_exists index("commits", [:commit_id, :service_name], unique: true)
  end
end
