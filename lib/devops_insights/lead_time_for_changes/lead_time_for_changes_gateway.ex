defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway do
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.IntervalFilter

  def get_lead_time_for_changes_metric(
        %IntervalFilter{start_date: start_date, end_date: end_date, interval: interval},
        dimensions \\ []
      ) do
    deployments = Repo.all(Deployment)
    commits = Repo.all(Commit)

    deploy_commits =
      Enum.reduce(deployments, %{}, fn %Deployment{commit_id: deploy_commit_id} = deploy, acc ->
        matching_commit =
          Enum.find(commits, fn %Commit{commit_id: commit_id} = c ->
            commit_id == deploy_commit_id
          end)

        acc |> Map.put(deploy.commit_id, {deploy, [matching_commit]})
      end)

    result =
      Enum.reduce(deploy_commits, [], fn {_, {%Deployment{} = deploy, commits}}, acc ->
        acc ++
          Enum.map(commits, fn %Commit{} = commit ->
            DateTime.diff(deploy.timestamp, commit.timestamp)
          end)
      end)

    if not (result |> Enum.empty?()) do
      {:ok, result |> median() |> round()}
    else
      {:error, "No deployments yet"}
    end
  end

  @spec median([number]) :: number | nil
  defp median([]), do: nil

  defp median(list) when is_list(list) do
    midpoint =
      (length(list) / 2)
      |> Float.floor()
      |> round

    {l1, l2} =
      Enum.sort(list)
      |> Enum.split(midpoint)

    case length(l2) > length(l1) do
      true ->
        [med | _] = l2
        med

      false ->
        [m1 | _] = l2
        [m2 | _] = Enum.reverse(l1)
        (m1 + m2) / 2
    end
  end
end
