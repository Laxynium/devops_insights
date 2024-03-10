defmodule DevopsInsights.DeploymentFrequencyMetricTest do
  alias DevopsInsights.EventsIngestion.Gateway
  use DevopsInsights.DataCase

  test "date range narrowd to single day" do
    [
      an_event(timestamp: ~U[2024-01-14 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-15 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z]),
      an_event(timestamp: ~U[2024-01-15 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-16 00:00:00Z])
    ]
    |> Enum.each(&Gateway.create_event(&1))

    assert [%{count: 3, group: 0}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-15], ~D[2024-01-15], 1)
  end

  test "date range across multiple days" do
    [
      an_event(timestamp: ~U[2024-01-14 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-15 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z]),
      an_event(timestamp: ~U[2024-01-15 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-16 00:00:00Z])
    ]
    |> Enum.each(&Gateway.create_event(&1))

    assert [%{count: 1, group: 0}, %{count: 3, group: 1}, %{count: 1, group: 2}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-16], 1)
  end

  test "internval length > 1" do
    [
      an_event(timestamp: ~U[2024-01-14 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-15 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z]),
      an_event(timestamp: ~U[2024-01-15 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-16 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-17 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-19 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-20 00:00:00Z])
    ]
    |> Enum.each(&Gateway.create_event(&1))

    assert [%{count: 5, group: 0}, %{count: 2, group: 1}, %{count: 1, group: 2}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-20], 3)
  end

  test "filter by extra service & env dimension" do
    [
      an_event(timestamp: ~U[2024-01-14 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-15 12:00:00Z], service_name: "app-1", environment: "qa"),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z], service_name: "app-1", environment: "qa"),
      an_event(timestamp: ~U[2024-01-16 12:00:00Z], service_name: "app-2", environment: "prod"),
      an_event(timestamp: ~U[2024-01-17 12:00:00Z], service_name: "app-2", environment: "qa")
    ]
    |> Enum.each(&Gateway.create_event(&1))

    assert [%{count: 3, group: 0}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-17], 4,
               serviceName: "app-1"
             )

    assert [%{count: 3, group: 0}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-17], 4,
               environmnet: "qa"
             )

    assert [%{count: 1, group: 0}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-17], 4,
               serviceName: "app-2",
               environmnet: "prod"
             )

    assert [%{count: 5, group: 0}] ==
             Gateway.get_deployment_frequency_metric(~D[2024-01-14], ~D[2024-01-17], 4,
               not_found_prop: "any"
             )
  end

  defp an_event(props) do
    %{
      timestamp: Keyword.get(props, :timestamp) || DateTime.utc_now(),
      type: :deployment,
      serviceName: Keyword.get(props, :service_name) || "devops_insights",
      environmnet: Keyword.get(props, :environment) || "prod"
    }
  end
end
