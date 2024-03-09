defmodule DevopsInsights.EventsIngestion.EventController do
  use DevopsInsightsWeb, :controller

  alias DevopsInsights.EventsIngestion.Gateway
  alias DevopsInsights.EventsIngestion.Event

  action_fallback DevopsInsightsWeb.FallbackController

  def index(conn, _params) do
    events = Gateway.list_events()
    render(conn, :index, events: events)
  end

  def create(conn, %{"event" => event_params}) do
    with {:ok, %Event{} = event} <- Gateway.create_event(event_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/events/#{event}")
      |> render(:show, event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = Gateway.get_event!(id)
    render(conn, :show, event: event)
  end
end
