defmodule DevopsInsights.EventsIngestion.EventsFilterTest do
  alias DevopsInsights.EventsIngestion.EventsFilter
  use DevopsInsights.DataCase

  describe "events filter" do
    test "create filter from map" do
      result =
        EventsFilter.from_map(%{
          "start_date" => "2024-03-01",
          "end_date" => "2024-03-15",
          "interval" => "7"
        })

      assert {:ok,
              %EventsFilter{
                start_date: Date.new!(2024, 03, 1),
                end_date: Date.new!(2024, 03, 15),
                interval: 7
              }} == result
    end

    test "filter to map" do
      {:ok, filter} =
        EventsFilter.from_map(%{
          "start_date" => "2024-03-01",
          "end_date" => "2024-03-15",
          "interval" => "7"
        })

      assert %{
               start_date: Date.new!(2024, 03, 1),
               end_date: Date.new!(2024, 03, 15),
               interval: 7
             } ==
               EventsFilter.to_map(filter)
    end
  end
end
