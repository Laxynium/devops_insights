defmodule DevopsInsights.EventsIngestion.EventLive.Index do
  require Logger
  alias Contex.BarChart
  alias Contex.Dataset
  alias Contex.Plot
  alias DevopsInsights.EventsIngestion.EventsFilter
  alias DevopsInsightsWeb.Endpoint
  use DevopsInsightsWeb, :live_view

  alias DevopsInsights.EventsIngestion.Deployments.DeploymentsGateway

  @impl true
  def mount(_params, _session, socket) do
    search_filters = %EventsFilter{
      start_date: Date.utc_today() |> Date.add(-13),
      end_date: Date.utc_today(),
      interval: 1
    }

    available_dimentions = DeploymentsGateway.get_available_dimentions()

    dimentions_filter =
      Map.keys(available_dimentions)
      |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x, nil) end)

    deployment_frequency =
      DeploymentsGateway.get_deployment_frequency_metric(search_filters)

    intervals_to_choose = ["1 day": 1, "1 week": 7, "2 weeks": 14, "1 month": 30]

    {:ok,
     socket
     |> assign(:intervals_to_choose, intervals_to_choose)
     |> assign(:available_dimentions, available_dimentions)
     |> assign(search_filters |> EventsFilter.to_map())
     |> assign(:dimentions_filter, dimentions_filter)
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
        %{assigns: %{dimentions_filter: dimentions_filter}} = socket
      ) do
    dimentions_filter =
      Map.keys(dimentions_filter)
      |> Enum.reduce(%{}, fn x, acc ->
        Map.put(acc, x, to_nil(Map.get(search_filters, to_string(x))))
      end)

    case EventsFilter.from_map(search_filters) do
      {:ok, search_filters} ->
        deployment_frequency =
          DeploymentsGateway.get_deployment_frequency_metric(
            search_filters,
            dimentions_filter
            |> Enum.map(fn {key, value} -> {key, value} end)
            |> Keyword.new()
          )

        {:noreply,
         socket
         |> assign(EventsFilter.to_map(search_filters))
         |> assign(:dimentions_filter, dimentions_filter)
         |> assign(:deployment_frequency, deployment_frequency)
         |> assign(:chart_svg, render_chart(deployment_frequency))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "event_ingested", payload: _},
        %{
          assigns: %{
            start_date: start_date,
            end_date: end_date,
            interval: interval,
            dimentions_filter: dimentions_filter
          }
        } = socket
      ) do
    search_filters = %EventsFilter{
      start_date: start_date,
      end_date: end_date,
      interval: interval
    }

    deployment_frequency =
      DeploymentsGateway.get_deployment_frequency_metric(search_filters, dimentions_filter)

    available_dimentions = DeploymentsGateway.get_available_dimentions()

    socket =
      socket
      |> assign(:deployment_frequency, deployment_frequency)
      |> assign(:available_dimentions, available_dimentions)
      |> assign(:chart_svg, render_chart(deployment_frequency))

    {:noreply, socket}
  end

  defp render_chart(deployment_frequency) do
    data =
      deployment_frequency
      |> Enum.map(fn %{count: count, group: _, start: start_date, end: end_date} ->
        {"[#{start_date}; #{end_date}]", count}
      end)

    ds = Dataset.new(data)

    Plot.new(ds, BarChart, 600, 400, custom_value_formatter: &"#{trunc(&1)}")
    |> Plot.axis_labels("Interval", "Count")
    |> Plot.to_svg()
  end

  defp to_nil("") do
    nil
  end

  defp to_nil(x) do
    x
  end
end
