defmodule DevopsInsights.EventsIngestion.Gateway do
  @moduledoc """
  The EventsIngestion context.
  """

  import Ecto.Query, warn: false
  alias DevopsInsights.EventsIngestion.EventsFilter
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo

  alias DevopsInsights.EventsIngestion.Event

  def list_events do
    Repo.all(Event)
  end

  @type event_groups :: %{count: non_neg_integer(), group: non_neg_integer()}

  @spec get_deployment_frequency_metric(%EventsFilter{}, keyword()) ::
          [event_groups()]
  def get_deployment_frequency_metric(%EventsFilter{} = events_filter, dimensions \\ []) do
    get_deployment_frequency_metric(
      events_filter.start_date,
      events_filter.end_date,
      events_filter.interval,
      dimensions
    )
  end

  @spec get_deployment_frequency_metric(Date.t(), Date.t(), non_neg_integer(), keyword()) ::
          [event_groups()]
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

    Repo.all(Event)
    |> Enum.filter(&Event.dimentions_matching?(&1, dimensions))
    |> Enum.filter(&Event.in_range?(&1, start, end_))
    |> Enum.group_by(&Event.calculate_group(&1, start, interval_in_days))
    |> Enum.map(fn {k, v} -> %{group: k, count: Enum.count(v)} end)
    |> Enum.reduce(intervals, fn g, acc ->
      Map.update!(acc, g.group, fn existing -> %{existing | count: g.count} end)
    end)
    |> Map.values()
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    event = %Event{}

    insert_result =
      event
      |> Event.changeset(attrs)
      |> Repo.insert()

    with {:ok, %Event{} = event} <- insert_result do
      Endpoint.broadcast("events", "event_ingested", event)
    end

    insert_result
  end
end
