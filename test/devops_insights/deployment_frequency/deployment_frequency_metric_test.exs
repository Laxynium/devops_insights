defmodule DevopsInsights.DeploymentFrequency.DeploymentFrequencyMetricTest do
  alias DevopsInsights.DeploymentFrequency.DeploymentFrequencyGateway
  alias DevopsInsights.EventsIngestion.IntervalFilter
  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway
  use DevopsInsights.DataCase

  test "date range narrowd to single day" do
    [
      an_event(timestamp: ~U[2024-01-14 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-15 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z]),
      an_event(timestamp: ~U[2024-01-15 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-16 00:00:00Z])
    ]
    |> Enum.each(fn x ->
      assert {:ok, _} = DeploymentsGateway.create_deployment(x)
    end)

    assert [%{count: 3, group: 0}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-15],
               end_date: ~D[2024-01-15],
               interval: 1
             })
  end

  test "date range across multiple days" do
    [
      an_event(timestamp: ~U[2024-01-14 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-15 00:00:00Z]),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z]),
      an_event(timestamp: ~U[2024-01-15 23:59:59Z]),
      an_event(timestamp: ~U[2024-01-16 00:00:00Z])
    ]
    |> Enum.each(&DeploymentsGateway.create_deployment(&1))

    assert [%{count: 1, group: 0}, %{count: 3, group: 1}, %{count: 1, group: 2}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-16],
               interval: 1
             })
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
    |> Enum.each(&DeploymentsGateway.create_deployment(&1))

    assert [%{count: 5, group: 0}, %{count: 2, group: 1}, %{count: 1, group: 2}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-20],
               interval: 3
             })
  end

  test "empty intervals" do
    [
      an_event(timestamp: ~U[2024-01-10 12:00:00Z]),
      an_event(timestamp: ~U[2024-01-11 12:00:00Z]),
      an_event(timestamp: ~U[2024-01-12 12:00:00Z]),
      an_event(timestamp: ~U[2024-01-16 12:00:00Z]),
      an_event(timestamp: ~U[2024-01-17 12:00:00Z])
    ]
    |> Enum.each(&DeploymentsGateway.create_deployment(&1))

    assert [%{count: 3, group: 0}, %{count: 0, group: 1}, %{count: 2, group: 2}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-10],
               end_date: ~D[2024-01-18],
               interval: 3
             })
  end

  test "filter by extra service & env dimension" do
    [
      an_event(timestamp: ~U[2024-01-14 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-15 12:00:00Z], service_name: "app-1", environment: "qa"),
      an_event(timestamp: ~U[2024-01-15 12:30:00Z], service_name: "app-1", environment: "qa"),
      an_event(timestamp: ~U[2024-01-16 12:00:00Z], service_name: "app-2", environment: "prod"),
      an_event(timestamp: ~U[2024-01-17 12:00:00Z], service_name: "app-2", environment: "qa")
    ]
    |> Enum.each(&DeploymentsGateway.create_deployment(&1))

    assert [%{count: 3, group: 0}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(
               %IntervalFilter{start_date: ~D[2024-01-14], end_date: ~D[2024-01-17], interval: 4},
               serviceName: "app-1"
             )

    assert [%{count: 3, group: 0}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(
               %IntervalFilter{start_date: ~D[2024-01-14], end_date: ~D[2024-01-17], interval: 4},
               environment: "qa"
             )

    assert [%{count: 1, group: 0}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(
               %IntervalFilter{start_date: ~D[2024-01-14], end_date: ~D[2024-01-17], interval: 4},
               serviceName: "app-2",
               environment: "prod"
             )

    assert [%{count: 5, group: 0}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(
               %IntervalFilter{start_date: ~D[2024-01-14], end_date: ~D[2024-01-17], interval: 4},
               not_found_prop: "any"
             )
  end

  test "calculate start and end for intervals" do
    [
      an_event(timestamp: ~U[2024-01-14 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-15 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-16 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-19 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-20 12:00:00Z], service_name: "app-1", environment: "prod"),
      an_event(timestamp: ~U[2024-01-21 12:00:00Z], service_name: "app-1", environment: "prod")
    ]
    |> Enum.each(&DeploymentsGateway.create_deployment(&1))

    assert [%{start: ~D[2024-01-14], end: ~D[2024-01-14]}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-14],
               interval: 1
             })

    assert [%{start: ~D[2024-01-14], end: ~D[2024-01-15]}] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-15],
               interval: 2
             })

    assert [
             %{start: ~D[2024-01-14], end: ~D[2024-01-15]},
             %{start: ~D[2024-01-16], end: ~D[2024-01-16]}
           ] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-16],
               interval: 2
             })

    assert [
             %{start: ~D[2024-01-14], end: ~D[2024-01-18]},
             %{start: ~D[2024-01-19], end: ~D[2024-01-23]},
             %{start: ~D[2024-01-24], end: ~D[2024-01-25]}
           ] =
             DeploymentFrequencyGateway.get_deployment_frequency_metric(%IntervalFilter{
               start_date: ~D[2024-01-14],
               end_date: ~D[2024-01-25],
               interval: 5
             })
  end

  defp an_event(props) do
    %{
      timestamp: Keyword.get(props, :timestamp) || DateTime.utc_now(),
      type: :deployment,
      serviceName: Keyword.get(props, :service_name) || "devops_insights",
      environment: Keyword.get(props, :environment) || "prod",
      commit_id: Keyword.get(props, :commit_id) || "1"
    }
  end
end
