defmodule DevopsInsightsWeb.EventLive.Index do
  alias Phoenix.PubSub
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion
  alias DevopsInsights.EventsIngestion.Event

  @impl true
  def mount(_params, _session, socket) do
    PubSub.subscribe(DevopsInsights.PubSub, "events")

    all_events = EventsIngestion.list_events()
    IO.inspect(all_events)
    {:ok, stream(socket, :events, all_events)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({:event_created, event}, socket) do
    {:noreply, stream_insert(socket, :events, event, at: 0)}
  end
end
