defmodule DevopsInsights.EventsIngestion.Deployments.DeploymentJSON do
  alias DevopsInsights.EventsIngestion.Deployments.Deployment

  @doc """
  Renders a list of deployments.
  """
  def index(%{deployments: deployments}) do
    %{data: for(event <- deployments, do: data(event))}
  end

  @doc """
  Renders a single deployments.
  """
  def show(%{deployment: deployment}) do
    %{data: data(deployment)}
  end

  defp data(%Deployment{} = deployment) do
    %{
      id: deployment.id,
      timestamp: deployment.timestamp,
      serviceName: deployment.serviceName,
      environment: deployment.environment,
      commit_id: deployment.commit_id
    }
  end
end
