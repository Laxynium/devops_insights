defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  require Logger
  alias DevopsInsights.EventsIngestion.EventsFilter
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Gateway

  @impl true
  def mount(_params, _session, socket) do
    events = Gateway.list_events() |> Enum.sort_by(& &1.timestamp, :desc)

    intervals_to_choose = ["1 day": 1, "1 week": 7, "2 weeks": 14, "1 month": 30]

    search_filters = %EventsFilter{
      start_date: Date.utc_today() |> Date.add(-13),
      end_date: Date.utc_today(),
      interval: 7
    }

    {:ok,
     stream(socket, :events, events)
     |> assign(:intervals_to_choose, intervals_to_choose)
     |> assign(search_filters |> EventsFilter.to_map())
     |> assign(:search_form, search_filters |> EventsFilter.to_map() |> to_form())
     |> assign(
       :deployment_frequency,
       Gateway.get_deployment_frequency_metric(search_filters)
     )}
  end

  @impl true
  def handle_params(_, _uri, socket) do
    if connected?(socket), do: Endpoint.subscribe("events")
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "apply_filters",
        %{"start_date" => _, "end_date" => _, "interval" => _} =
          search_filters,
        socket
      ) do
    with {:ok, search_filters} = EventsFilter.from_map(search_filters) do
      {:noreply,
       socket
       |> assign(EventsFilter.to_map(search_filters))
       |> assign(
         :deployment_frequency,
         Gateway.get_deployment_frequency_metric(search_filters)
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "event_ingested", payload: event},
        %{assigns: %{start_date: _, end_date: _, interval: _} = search_filters} = socket
      ) do
    updated_socket = stream_insert(socket, :events, event, at: 0)

    updated_socket =
      updated_socket
      |> assign(
        :deployment_frequency,
        Gateway.get_deployment_frequency_metric(search_filters)
      )

    {:noreply, updated_socket}
  end
end
