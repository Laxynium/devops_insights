defmodule DevopsInsights.EventsIngestion do
  @moduledoc """
  The EventsIngestion context.
  """

  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias DevopsInsights.Repo

  alias DevopsInsights.EventsIngestion.Event

  def list_events do
    Repo.all(Event)
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    event = %Event{}

    insert_result =
      event
      |> Event.changeset(attrs)
      |> Repo.insert()

    with {:ok, %Event{} = event} <- insert_result do
      PubSub.broadcast(DevopsInsights.PubSub, "events", {:event_created, event})
    end

    insert_result
  end
end
