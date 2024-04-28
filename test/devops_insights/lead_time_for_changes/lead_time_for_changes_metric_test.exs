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
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"}
    ]
    |> apply_events()

    assert {:error, "No deployments yet"} = get_lead_time_for_changes_metric()
  end

  test "single deployment single commit" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :deploy, commit_id: "1", timestamp: "2024-04-04T19:10:00Z"}
    ]
    |> apply_events()

    assert {:ok, 600} = get_lead_time_for_changes_metric()
  end

  test "each commit is deployed" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :deploy, commit_id: "1", timestamp: "2024-04-04T19:12:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"}
    ]
    |> apply_events()

    assert {:ok, 660} = get_lead_time_for_changes_metric()
  end

  test "commits gap between deployments" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"}
    ]
    |> apply_events()

    assert {:ok, 900} = get_lead_time_for_changes_metric()
  end

  test "deploy each second commit" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :commit, commit_id: "3", parent_id: "2", timestamp: "2024-04-04T19:15:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"},
      %{type: :commit, commit_id: "4", parent_id: "3", timestamp: "2024-04-04T19:30:00Z"},
      %{type: :commit, commit_id: "5", parent_id: "4", timestamp: "2024-04-04T19:35:00Z"},
      %{type: :deploy, commit_id: "5", timestamp: "2024-04-04T19:40:00Z"}
    ]
    |> apply_events()

    assert {:ok, 600} = get_lead_time_for_changes_metric()
  end

  defp apply_events(events) do
    events |> Enum.each(&apply_event/1)
  end

  defp apply_event(%{type: :commit} = commit) do
    if(commit.parent_id == nil) do
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

  defp get_lead_time_for_changes_metric() do
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
