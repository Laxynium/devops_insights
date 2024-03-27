defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  require Logger
  alias DevopsInsights.EventsIngestion.Event
  alias Contex.BarChart
  alias Contex.ContinuousLinearScale
  alias Contex.PointPlot
  alias Contex.Dataset
  alias Contex.Plot
  alias DevopsInsights.EventsIngestion.EventsFilter
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Gateway

  @impl true
  def mount(_params, _session, socket) do
    events = Gateway.list_events() |> Enum.sort_by(& &1.timestamp, :desc)

    dimentions = %{
      serviceName: %{displayName: "Service Name", values: MapSet.new()},
      environment: %{displayName: "Environment", values: MapSet.new()}
    }

    selectable_dimentions =
      events
      |> Enum.reduce(dimentions, fn event, acc ->
        Map.keys(acc)
        |> Enum.reduce(acc, fn dim, result ->
          Map.update!(result, dim, fn %{} = nested ->
            Map.put(nested, :values, MapSet.put(nested.values, Map.get(event, dim)))
          end)
        end)
      end)

    IO.inspect(selectable_dimentions)

    intervals_to_choose = ["1 day": 1, "1 week": 7, "2 weeks": 14, "1 month": 30]

    search_filters = %EventsFilter{
      start_date: Date.utc_today() |> Date.add(-13),
      end_date: Date.utc_today(),
      interval: 1
    }

    deployment_frequency = Gateway.get_deployment_frequency_metric(search_filters)

    {:ok,
     stream(socket, :events, events)
     |> assign(:intervals_to_choose, intervals_to_choose)
     |> assign(:selectable_dimentions, selectable_dimentions)
     |> assign(search_filters |> EventsFilter.to_map())
     |> assign(:search_form, search_filters |> EventsFilter.to_map() |> to_form())
     |> assign(:chart_svg, render_chart(deployment_frequency))
     |> assign(
       :deployment_frequency,
       deployment_frequency
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
      deployment_frequency = Gateway.get_deployment_frequency_metric(search_filters)

      {:noreply,
       socket
       |> assign(EventsFilter.to_map(search_filters))
       |> assign(:deployment_frequency, deployment_frequency)
       |> assign(:chart_svg, render_chart(deployment_frequency))}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "event_ingested", payload: event},
        %{
          assigns: %{start_date: start_date, end_date: end_date, interval: interval}
        } = socket
      ) do
    updated_socket = stream_insert(socket, :events, event, at: 0)

    search_filters = %EventsFilter{
      start_date: start_date,
      end_date: end_date,
      interval: interval
    }

    deployment_frequency = Gateway.get_deployment_frequency_metric(search_filters)

    updated_socket =
      updated_socket
      |> assign(:deployment_frequency, deployment_frequency)
      |> assign(:chart_svg, render_chart(deployment_frequency))

    {:noreply, updated_socket}
  end

  defp render_chart(deployment_frequency) do
    data =
      deployment_frequency
      |> Enum.map(fn %{count: count, group: interval, start: start_date, end: end_date} ->
        {"[#{start_date};#{end_date}]", count}
      end)

    ds = Dataset.new(data)

    Plot.new(ds, BarChart, 600, 400, custom_value_formatter: &"#{trunc(&1)}")
    |> Plot.axis_labels("Interval", "Count")
    |> Plot.to_svg()
  end
end
