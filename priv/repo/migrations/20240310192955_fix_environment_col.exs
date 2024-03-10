defmodule DevopsInsights.Repo.Migrations.FixEnvironmentCol do
  use Ecto.Migration

  def change do
    rename table("events"), :environmnet, to: :environment
  end
end
