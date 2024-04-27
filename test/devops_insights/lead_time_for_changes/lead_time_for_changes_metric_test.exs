defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesMetricTest do
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.EventsIngestion.IntervalFilter
  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway
  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway
  alias DevopsInsights.EventsIngestion.Commits.CommitsGateway
  alias DevopsInsights.EventsIngestion
  use DevopsInsights.DataCase

  test "no deployments single commit" do
    assert {:ok, _} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:00:00Z"
             })

    assert {:error, "No deployments yet"} =
             LeadTimeForChangesGateway.get_lead_time_for_changes_metric(
               %IntervalFilter{
                 start_date: ~D[2024-01-01],
                 end_date: ~D[2025-01-01],
                 interval: 365
               },
               service_name: "app-1",
               environment: "prod"
             )
  end

  test "single deployment single commit" do
    assert {:ok, _} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:00:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "1",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:10:00Z"
             })

    assert {:ok, 600} =
             LeadTimeForChangesGateway.get_lead_time_for_changes_metric(
               %IntervalFilter{
                 start_date: ~D[2024-01-01],
                 end_date: ~D[2025-01-01],
                 interval: 365
               },
               service_name: "app-1",
               environment: "prod"
             )
  end

  test "each commit is deployed" do
    assert {:ok, _} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:00:00Z"
             })

    assert {:ok, _} =
             CommitsGateway.create_commit(%{
               "commit_id" => "2",
               "parent_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:10:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "1",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:12:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "2",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:20:00Z"
             })

    assert {:ok, 660} =
             LeadTimeForChangesGateway.get_lead_time_for_changes_metric(
               %IntervalFilter{
                 start_date: ~D[2024-01-01],
                 end_date: ~D[2025-01-01],
                 interval: 365
               },
               service_name: "app-1",
               environment: "prod"
             )
  end
end

defmodule DevopsInsights.LeadTimeForChanges.FindingDeployCommitsTest do
  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway.DeployCommits
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.EventsIngestion.Commits.CommitsGateway
  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway
  alias DevopsInsights.EventsIngestion
  use DevopsInsights.DataCase

  test "get all deploy commits - single deploy" do
    assert {:ok, _} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:00:00Z"
             })

    assert {:ok, _} =
             CommitsGateway.create_commit(%{
               "commit_id" => "2",
               "parent_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:10:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "2",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:12:00Z"
             })

    assert [{%Deployment{commit_id: "2"}, [%Commit{commit_id: "2"}, %Commit{commit_id: "1"}]}] =
             get_deploy_commits()
  end

  test "get all deploy commits - few deploys" do
    assert {:ok, _} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:00:00Z"
             })

    assert {:ok, _} =
             CommitsGateway.create_commit(%{
               "commit_id" => "2",
               "parent_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:10:00Z"
             })

    assert {:ok, _} =
             CommitsGateway.create_commit(%{
               "commit_id" => "3",
               "parent_id" => "2",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:10:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "1",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:12:00Z"
             })

    assert {:ok, _} =
             DeploymentsGateway.create_deployment(%{
               "commit_id" => "3",
               "serviceName" => "app-1",
               "environment" => "prod",
               "timestamp" => "2024-04-04T19:12:00Z"
             })

    assert [
             {%Deployment{commit_id: "1"}, [%Commit{commit_id: "1"}]},
             {%Deployment{commit_id: "3"}, [%Commit{commit_id: "3"}, %Commit{commit_id: "2"}]}
           ] =
             get_deploy_commits()
  end

  defp get_deploy_commits() do
    commits = Repo.all(Commit)
    deploys = Repo.all(Deployment)
    DeployCommits.get_deploy_commits(commits, deploys)
  end
end
