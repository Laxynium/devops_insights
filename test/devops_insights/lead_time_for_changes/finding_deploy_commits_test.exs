defmodule DevopsInsights.LeadTimeForChanges.FindingDeployCommitsTest do
  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway.DeployCommits
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  use DevopsInsights.DataCase

  test "get all deploy commits - single deploy" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:12:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert [{%Deployment{commit_id: "2"}, [%Commit{commit_id: "2"}, %Commit{commit_id: "1"}]}] =
             get_deploy_commits()
  end

  test "get all deploy commits - few deploys" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :commit, commit_id: "3", parent_id: "2", timestamp: "2024-04-04T19:12:00Z"},
      %{type: :deploy, commit_id: "1", timestamp: "2024-04-04T19:15:00Z"},
      %{type: :deploy, commit_id: "3", timestamp: "2024-04-04T19:20:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert [
             {%Deployment{commit_id: "1"}, [%Commit{commit_id: "1"}]},
             {%Deployment{commit_id: "3"}, [%Commit{commit_id: "3"}, %Commit{commit_id: "2"}]}
           ] = get_deploy_commits()
  end

  defp get_deploy_commits() do
    commits = Repo.all(Commit)
    deploys = Repo.all(Deployment)
    DeployCommits.get_deploy_commits(commits, deploys)
  end
end
