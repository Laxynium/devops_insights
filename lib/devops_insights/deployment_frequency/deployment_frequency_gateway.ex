defmodule DevopsInsights.DeploymentFrequency.DeploymentFrequencyGateway do
  alias DevopsInsights.EventsIngestion.IntervalFilter
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.Deployments.Deployment

  def get_available_dimentions do
    dimentions = %{
      serviceName: %{displayName: "Service Name", values: MapSet.new([nil])},
      environment: %{displayName: "Environment", values: MapSet.new([nil])}
    }

    Repo.all(Deployment)
    |> Enum.reduce(dimentions, fn deployment, acc ->
      Map.keys(acc)
      |> Enum.reduce(acc, fn dim, result ->
        Map.update!(result, dim, &set_dimention_values(&1, deployment, dim))
      end)
    end)
  end

  defp set_dimention_values(%{values: values} = dimention, deployment, dim) do
    Map.put(dimention, :values, MapSet.put(values, Map.get(deployment, dim)))
  end

  @type deployment_groups :: %{count: non_neg_integer(), group: non_neg_integer()}

  @spec get_deployment_frequency_metric(IntervalFilter.t(), keyword()) ::
          [deployment_groups()]
  def get_deployment_frequency_metric(%IntervalFilter{} = events_filter, dimensions \\ []) do
    get_deployment_frequency_metric(
      events_filter.start_date,
      events_filter.end_date,
      events_filter.interval,
      dimensions
    )
  end

  @spec get_deployment_frequency_metric(Date.t(), Date.t(), non_neg_integer(), keyword()) ::
          [deployment_groups()]
  defp get_deployment_frequency_metric(start, end_, interval_in_days, dimensions) do
    intervals =
      Stream.iterate(0, &(&1 + 1))
      |> Enum.take(((Date.diff(end_, start) / interval_in_days) |> trunc()) + 1)
      |> Enum.reduce(Map.new(), fn x, acc ->
        Map.put(acc, x, %{
          group: x,
          count: 0,
          start: Date.add(start, x * interval_in_days),
          end: min(end_, Date.add(start, (x + 1) * interval_in_days) |> Date.add(-1))
        })
      end)

    Repo.all(Deployment)
    |> Enum.filter(
      &(Deployment.dimentions_matching?(&1, dimensions) and Deployment.in_range?(&1, start, end_))
    )
    |> Enum.group_by(&Deployment.calculate_group(&1, start, interval_in_days))
    |> Enum.map(fn {k, v} -> %{group: k, count: Enum.count(v)} end)
    |> Enum.reduce(intervals, fn g, acc ->
      Map.update!(acc, g.group, fn existing -> %{existing | count: g.count} end)
    end)
    |> Map.values()
  end
end
