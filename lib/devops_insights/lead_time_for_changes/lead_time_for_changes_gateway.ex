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

  defmodule DeployCommits do
    def get_deploy_commits(commits, deploys) do
      commits = commits |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x.commit_id, x) end)

      deploys = [nil] ++ (deploys |> Enum.sort_by(& &1.timestamp))
      deploys = Enum.zip(deploys, Enum.drop(deploys, 1))

      deploys_commits =
        Enum.reduce(deploys, [], fn {previous_deploy,
                                     %{commit_id: deploy_commit_id} = current_deploy},
                                    deploys_acc ->
          stop_fn =
            if previous_deploy != nil do
              fn c -> c.commit_id == previous_deploy.commit_id end
            else
              fn c -> false end
            end

          current_deploy_commits =
            get_all_previous_commits(commits, deploy_commit_id, stop_fn)

          deploys_acc ++ [{current_deploy, current_deploy_commits}]
        end)

      deploys_commits
    end

    def get_all_previous_commits(commits_map, commit_id, stop_condition) do
      get_all_previous_commits_stream(commits_map, commit_id, stop_condition)
      |> Stream.drop_while(fn {state, _, _} -> state != :done end)
      |> Enum.take(1)
      |> Enum.flat_map(fn {_, _, result} -> result end)
    end

    def get_all_previous_commits_stream(commits_map, commit_id, stop_condition) do
      Stream.iterate(1, & &1)
      |> Stream.scan({:running, nil, []}, fn _, acc ->
        case acc do
          {:running, nil, []} ->
            next_commit = commits_map |> Map.fetch!(commit_id)

            if stop_condition.(next_commit) do
              {:done, nil, []}
            else
              {:running, next_commit, [next_commit]}
            end

          {:running, commit, result} ->
            cond do
              stop_condition.(commit) ->
                {:done, commit, result}

              commit.parent_id == nil ->
                {:done, commit, result}

              true ->
                next_commit = commits_map |> Map.fetch!(commit.parent_id)

                if stop_condition.(next_commit) do
                  {:done, commit, result}
                else
                  {:running, next_commit, result ++ [next_commit]}
                end
            end

          {:done, state, result} ->
            {:done, state, result}
        end
      end)
    end
  end
end
