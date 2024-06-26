defmodule DevopsInsights.EventsIngestion.Deployments.DeploymentController do
  use DevopsInsightsWeb, :controller

  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway
  alias DevopsInsights.EventsIngestion.Deployments.Deployment

  action_fallback DevopsInsightsWeb.FallbackController

  def index(conn, _params) do
    deployments = DeploymentsGateway.list_deployments()
    render(conn, :index, deployments: deployments)
  end

  def create(conn, %{"event" => deployment_params}) do
    with {:ok, %Deployment{} = deployment} <-
           DeploymentsGateway.create_deployment(deployment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/deployments/#{deployment}")
      |> render(:show, deployment: deployment)
    end
  end

  def show(conn, %{"id" => id}) do
    deployment = DeploymentsGateway.get_deployment!(id)
    render(conn, :show, deployment: deployment)
  end
end
