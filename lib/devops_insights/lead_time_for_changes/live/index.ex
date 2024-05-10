defmodule DevopsInsights.LeadTimeForChanges.Live.Index do
  @moduledoc false

  alias DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway
  alias DevopsInsights.EventsIngestion.IntervalFilter
  use DevopsInsightsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    search_filters = %IntervalFilter{
      start_date: Date.utc_today() |> Date.add(-13),
      end_date: Date.utc_today(),
      interval: 1
    }

    available_dimentions = %{
      serviceName: %{displayName: "Service Name", values: MapSet.new([nil, "app-1", "app-2"])}
    }

    lead_time_for_changes =
      LeadTimeForChangesGateway.get_lead_time_for_changes_metric(search_filters)

    #
    dimentions_filter =
      Map.keys(available_dimentions)
      |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x, nil) end)

    intervals_to_choose = ["1 day": 1, "1 week": 7, "2 weeks": 14, "1 month": 30]

    {:ok,
     socket
     |> assign(:available_dimentions, available_dimentions)
     |> assign(:intervals_to_choose, intervals_to_choose)
     |> assign(:dimentions_filter, dimentions_filter)
     |> assign(search_filters |> IntervalFilter.to_map())}
  end

  @impl true
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end
end
