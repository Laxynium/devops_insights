defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Gateway

  @impl true
  def mount(_params, _session, socket) do
    events = Gateway.list_events() |> Enum.sort_by(& &1.timestamp, :desc)

    {:ok,
     stream(socket, :events, events)
     |> stream(:deployment_frequency, get_deployment_frequences_from_last_month())}
  end

  @impl true
  def handle_params(_, _uri, socket) do
    if connected?(socket), do: Endpoint.subscribe("events")
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "event_ingested", payload: event}, socket) do
    updated_socket = stream_insert(socket, :events, event, at: 0)

    updated_socket =
      get_deployment_frequences_from_last_month()
      |> Enum.reduce(updated_socket, fn x, s -> stream_insert(s, :deployment_frequency, x) end)

    {:noreply, updated_socket}
  end

  defp get_deployment_frequences_from_last_month() do
    now = DateTime.utc_now() |> DateTime.to_date()

    Gateway.get_deployment_frequency_metric(
      now |> Date.add(-31),
      now,
      7
    )
    |> Enum.map(fn x ->
      %{id: x.group, group: x.group, count: x.count, start: x.start, end: x.end}
    end)
  end
end
