defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway do
  @moduledoc false

  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway.DeployCommits
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.IntervalFilter

  def get_lead_time_for_changes_metric(
        %IntervalFilter{start_date: start_date, end_date: end_date, interval: interval_in_days} =
          interval,
        _dimensions \\ []
      ) do
    commits = Repo.all(Commit)
    deployments = Repo.all(Deployment)

    buckets = get_buckets(interval)

    filtered_deployments =
      deployments
      |> Enum.filter(fn %Deployment{timestamp: timestamp} ->
        Date.compare(DateTime.to_date(timestamp), start_date) in [:gt, :eq] and
          Date.compare(DateTime.to_date(timestamp), end_date) in [:lt, :eq]
      end)

    # TODO calculate a bucket number based on timestamp and put deploy to matching bucket
    # TODO: Need to split into intervals
    deploy_commits =
      DeployCommits.get_deploy_commits(commits, deployments, fn %Deployment{timestamp: timestamp} ->
        Date.compare(DateTime.to_date(timestamp), start_date) in [:gt, :eq] &&
          Date.compare(DateTime.to_date(timestamp), end_date) in [:lt, :eq]
      end)

    result =
      Enum.reduce(deploy_commits, [], fn {%Deployment{} = deploy, commits}, acc ->
        acc ++
          Enum.map(commits, fn %Commit{} = commit ->
            DateTime.diff(deploy.timestamp, commit.timestamp)
          end)
      end)

    if result |> Enum.any?() do
      {:ok, result |> median() |> round()}
    else
      {:error, "No deployments yet"}
    end
  end

  defp get_buckets(%IntervalFilter{start_date: start_date, end_date: end_date, interval: interval}) do
    buckets =
      Stream.iterate(0, &(&1 + 1))
      |> Enum.take(((Date.diff(end_date, start_date) / interval) |> trunc()) + 1)
      |> Enum.map(fn x -> {x, []} end)
      |> Map.new()

    buckets
  end

  def calculate_bucket(datetime, start_date, interval_in_days) do
    interval_in_seconds = interval_in_days * 24 * 60 * 60
    datetime_in_seconds = DateTime.to_unix(datetime)
    start_in_seconds = DateTime.to_unix(DateTime.new!(start_date, ~T[00:00:00Z]))

    diff = datetime_in_seconds - start_in_seconds + 1
    (diff / interval_in_seconds) |> Float.ceil() |> trunc()
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
    @moduledoc false

    def get_deploy_commits(commits, deploys, deploys_filter \\ fn _ -> true end) do
      commits = commits |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x.commit_id, x) end)

      deploys = deploys |> Enum.sort_by(& &1.timestamp)

      deploys =
        Enum.zip([nil] ++ deploys, deploys)
        |> Enum.filter(fn {_, d} -> deploys_filter.(d) end)

      deploys_commits =
        Enum.reduce(deploys, [], fn {previous_deploy,
                                     %{commit_id: deploy_commit_id} = current_deploy},
                                    deploys_acc ->
          stop_fn = get_stop_fn(previous_deploy)

          current_deploy_commits =
            get_all_previous_commits(commits, deploy_commit_id, stop_fn)

          deploys_acc ++ [{current_deploy, current_deploy_commits}]
        end)

      deploys_commits
    end

    defp get_stop_fn(previous_deploy) do
      if previous_deploy != nil do
        fn c -> c.commit_id == previous_deploy.commit_id end
      else
        fn _ -> false end
      end
    end

    def get_all_previous_commits(commits_map, commit_id, stop_condition) do
      get_all_previous_commits_stream(commits_map, commit_id, stop_condition)
      |> then(fn {_, result} -> result end)
    end

    def get_all_previous_commits_stream(commits_map, commit_id, stop_condition) do
      Stream.iterate(1, & &1)
      |> Enum.reduce_while({nil, []}, fn _, acc ->
        process_commit(commits_map, commit_id, stop_condition, acc)
      end)
    end

    defp process_commit(commits_map, initial_commit_id, stop_condition, {nil, []}) do
      next_commit = commits_map |> Map.fetch!(initial_commit_id)

      if stop_condition.(next_commit) do
        {:halt, {nil, []}}
      else
        {:cont, {next_commit, [next_commit]}}
      end
    end

    defp process_commit(commits_map, _, stop_condition, {commit, result}) do
      cond do
        stop_condition.(commit) ->
          {:halt, {commit, result}}

        commit.parent_id == nil ->
          {:halt, {commit, result}}

        true ->
          next_commit = commits_map |> Map.fetch!(commit.parent_id)

          if stop_condition.(next_commit) do
            {:halt, {commit, result}}
          else
            {:cont, {next_commit, result ++ [next_commit]}}
          end
      end
    end
  end
end
