defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  require Logger
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
      |> Enum.map(fn %{count: count, group: interval} -> {interval, count} end)

    {_, max_interval} =
      deployment_frequency
      |> Enum.map(fn %{group: group} -> group end)
      |> Enum.min_max()

    {_, max_count} =
      deployment_frequency
      |> Enum.map(fn %{count: count} -> count end)
      |> Enum.min_max()

    x_scale =
      ContinuousLinearScale.new()
      |> ContinuousLinearScale.domain(0, max_interval)
      |> ContinuousLinearScale.interval_count(max_interval + 1)

    y_scale =
      ContinuousLinearScale.new()
      |> ContinuousLinearScale.domain(0, max_count)
      |> ContinuousLinearScale.interval_count(max_count + 1)

    ds = Dataset.new(data)

    Plot.new(ds, PointPlot, 600, 400, custom_x_scale: x_scale, custom_y_scale: y_scale)
    |> Plot.axis_labels("Interval", "Count")
    |> Plot.to_svg()
  end
end
