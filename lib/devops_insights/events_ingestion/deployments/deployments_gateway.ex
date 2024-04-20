defmodule DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway do
  @moduledoc """
  The EventsIngestion context.
  """

  import Ecto.Query, warn: false
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo

  alias DevopsInsights.EventsIngestion.Deployments.Deployment

  def list_deployments do
    Repo.all(Deployment)
  end

  def get_deployment!(id), do: Repo.get!(Deployment, id)

  def create_deployment(attrs \\ %{}) do
    deployment = %Deployment{}

    insert_result =
      deployment
      |> Deployment.changeset(attrs)
      |> Repo.insert()

    with {:ok, %Deployment{} = deployment} <- insert_result do
      Endpoint.broadcast("events", "event_ingested", deployment)
    end

    insert_result
  end
end
