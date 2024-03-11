defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Gateway

  @impl true
  def mount(_params, _session, socket) do
    events = Gateway.list_events() |> Enum.sort_by(& &1.timestamp, :desc)

    now = DateTime.utc_now() |> DateTime.to_date()

    deployment_frequency =
      Gateway.get_deployment_frequency_metric(
        now |> Date.add(-31),
        now,
        7
      )
      |> Enum.map(fn x -> %{id: x.group, group: x.group, count: x.count} end)

    IO.inspect(deployment_frequency)

    {:ok,
     stream(socket, :events, events)
     |> stream(:deployment_frequency, deployment_frequency)}
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
