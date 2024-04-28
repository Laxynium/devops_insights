defmodule MetricFixtures do
  @moduledoc false

  alias DevopsInsights.EventsIngestion.Commits.CommitsGateway
  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway
  alias DevopsInsights.EventsIngestion.IntervalFilter
  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway
  use DevopsInsights.DataCase

  def apply_events(events) do
    events |> Enum.each(&apply_event/1)
  end

  defp apply_event(%{type: :commit} = commit) do
    if commit.parent_id == nil do
      assert {:ok, _} =
               CommitsGateway.create_root_commit(%{
                 "commit_id" => commit.commit_id,
                 "service_name" => "app-1",
                 "timestamp" => commit.timestamp
               })
    else
      assert {:ok, _} =
               CommitsGateway.create_commit(%{
                 "commit_id" => commit.commit_id,
                 "parent_id" => commit.parent_id,
                 "service_name" => "app-1",
                 "timestamp" => commit.timestamp
               })
    end
  end

  defp apply_event(%{type: :deploy} = deploy) do
    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => deploy.commit_id,
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => deploy.timestamp
             })
  end

  def get_lead_time_for_changes_metric() do
    LeadTimeForChangesGateway.get_lead_time_for_changes_metric(
      %IntervalFilter{
        start_date: ~D[2020-01-01],
        end_date: ~D[2030-01-01],
        interval: 365 * 10
      },
      service_name: "app-1",
      environment: "prod"
    )
  end
end
