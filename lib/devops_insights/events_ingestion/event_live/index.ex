defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  require Logger
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Gateway

  @impl true
  def mount(_params, _session, socket) do
    events = Gateway.list_events() |> Enum.sort_by(& &1.timestamp, :desc)

    start_date = Date.utc_today() |> Date.add(-13)
    end_date = Date.utc_today()
    interval_in_days = 7
    intervals_to_choose = ["1 day": 1, "1 week": 7, "2 weeks": 14, "1 month": 30]

    {:ok,
     stream(socket, :events, events)
     |> assign(:intervals_to_choose, intervals_to_choose)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:interval, interval_in_days)
     |> assign(
       :search_form,
       to_form(%{start_date: start_date, end_date: end_date, interval: interval_in_days})
     )
     |> assign(
       :deployment_frequency,
       get_deployment_frequences(start_date, end_date, interval_in_days)
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
        %{"start_date" => start_date, "end_date" => end_date, "interval" => interval_in_days},
        socket
      ) do
    {:ok, start_date} = Date.from_iso8601(start_date)
    {:ok, end_date} = Date.from_iso8601(end_date)
    {interval_in_days, _} = Integer.parse(interval_in_days)

    updated_socket =
      socket
      |> assign(
        :start_date,
        start_date
      )
      |> assign(
        :end_date,
        end_date
      )
      |> assign(
        :interval,
        interval_in_days
      )
      |> assign(
        :deployment_frequency,
        get_deployment_frequences(
          start_date,
          end_date,
          interval_in_days
        )
      )

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info(
        %{event: "event_ingested", payload: event},
        %{assigns: %{start_date: start_date, end_date: end_date, interval: interval_in_days}} =
          socket
      ) do
    updated_socket = stream_insert(socket, :events, event, at: 0)

    updated_socket =
      updated_socket
      |> assign(
        :deployment_frequency,
        get_deployment_frequences(start_date, end_date, interval_in_days)
      )

    {:noreply, updated_socket}
  end

  defp get_deployment_frequences(start, end_, interval_in_days) do
    Gateway.get_deployment_frequency_metric(
      start,
      end_,
      interval_in_days
    )
  end
end
