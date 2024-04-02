defmodule DevopsInsights.EventsIngestion.DeploymentJSON do
  alias DevopsInsights.EventsIngestion.Deployment

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
      environment: deployment.environment
    }
  end
end
