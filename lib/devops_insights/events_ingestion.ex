defmodule DevopsInsights.EventsIngestion do
  @moduledoc """
  The EventsIngestion context.
  """

  import Ecto.Query, warn: false
  alias DevopsInsights.Repo

  alias DevopsInsights.EventsIngestion.Event

  def list_events do
    Repo.all(Event)
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end
end
