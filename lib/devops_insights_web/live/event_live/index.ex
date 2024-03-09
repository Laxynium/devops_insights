defmodule DevopsInsightsWeb.EventLive.Index do
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :events, EventsIngestion.list_events() |> Enum.sort_by(& &1.timestamp, :desc))}
  end

  @impl true
  def handle_params(_, _uri, socket) do
    if connected?(socket), do: Endpoint.subscribe("events")
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "event_ingested", payload: event}, socket) do
    {:noreply, stream_insert(socket, :events, event, at: 0)}
  end
end
