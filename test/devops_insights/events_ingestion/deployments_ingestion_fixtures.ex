defmodule DevopsInsights.EventsIngestionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DevopsInsights.EventsIngestion` context.
  """

  @doc """
  Generate a event.
  """
  def deployment_fixture(attrs \\ %{}) do
    {:ok, deployment} =
      attrs
      |> Enum.into(%{
        environment: "some environment",
        serviceName: "some serviceName",
        timestamp: ~U[2024-03-06 22:39:00Z]
      })
      |> DevopsInsights.EventsIngestion.DeploymentsGateway.create_deployment()

    deployment
  end
end
