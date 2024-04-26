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

    assert [%Commit{commit_id: "2"}, %Commit{commit_id: "1"}] = get_deploy_commits("2")
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

    assert [%Commit{commit_id: "3"}, %Commit{commit_id: "2"}] = get_deploy_commits("3")
  end

  defp get_deploy_commits(deploy_commit_id) do
    deploys = Repo.all(Deployment) |> Enum.sort_by(& &1.timestamp)
    commits = Repo.all(Commit)

    deploy_index = Enum.find_index(deploys, &(&1.commit_id == deploy_commit_id))

    base_commit_id =
      if deploy_index >= 1 do
        Enum.at(deploys, deploy_index - 1).commit_id
      else
        nil
      end

    commit = Enum.find(commits, &(&1.commit_id == deploy_commit_id))

    deploy_commits =
      Stream.iterate(1, & &1)
      |> Stream.scan({:running, {commit, [commit]}}, fn _, acc ->
        case acc do
          {:running, {current_commit, current_commits}} ->
            next_commit = Enum.find(commits, &(&1.commit_id == current_commit.parent_id))

            cond do
              next_commit.commit_id == base_commit_id ->
                {:done, {next_commit, current_commits}}

              next_commit.parent_id == nil ->
                {:done, {next_commit, current_commits ++ [next_commit]}}

              true ->
                {:running, {next_commit, current_commits ++ [next_commit]}}
            end

          {:done, result} ->
            {:done, result}
        end
      end)
      |> Stream.drop_while(fn {status, _} -> status != :done end)
      |> Enum.take(1)
      |> Enum.flat_map(fn {_, {_, result}} -> result end)

    deploy_commits
  end
end
