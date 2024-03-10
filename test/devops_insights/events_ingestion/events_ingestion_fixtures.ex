defmodule DevopsInsights.EventsIngestionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DevopsInsights.EventsIngestion` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        environment: "some environment",
        serviceName: "some serviceName",
        timestamp: ~U[2024-03-06 22:39:00Z],
        type: :deployment
      })
      |> DevopsInsights.EventsIngestion.Gateway.create_event()

    event
  end
end
