defmodule DevopsInsights.EventsIngestion.Gateway do
  @moduledoc """
  The EventsIngestion context.
  """

  import Ecto.Query, warn: false
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo

  alias DevopsInsights.EventsIngestion.Event

  def list_events do
    Repo.all(Event)
  end

  @type event_groups :: %{count: non_neg_integer(), group: non_neg_integer()}
  @spec list_events(Date.t(), Date.t(), non_neg_integer()) :: [event_groups()]
  def list_events(start, end_, interval_in_days) do
    Repo.all(Event)
    |> Enum.filter(&Event.in_range?(&1, start, end_))
    |> Enum.group_by(&Event.calculate_group(&1, start, interval_in_days))
    |> Enum.map(fn {k, v} -> %{group: k, count: Enum.count(v)} end)
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
