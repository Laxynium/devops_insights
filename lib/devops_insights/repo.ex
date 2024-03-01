defmodule DevopsInsights.Repo do
  use Ecto.Repo,
    otp_app: :devops_insights,
    adapter: Ecto.Adapters.Postgres
end
