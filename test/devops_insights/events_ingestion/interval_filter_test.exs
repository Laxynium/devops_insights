defmodule DevopsInsights.EventsIngestion.IntervalFilterTest do
  alias DevopsInsights.EventsIngestion.IntervalFilter
  use DevopsInsights.DataCase

  describe "events filter" do
    test "create filter from map" do
      result =
        IntervalFilter.from_map(%{
          "start_date" => "2024-03-01",
          "end_date" => "2024-03-15",
          "interval" => "7"
        })

      assert {:ok,
              %IntervalFilter{
                start_date: Date.new!(2024, 03, 1),
                end_date: Date.new!(2024, 03, 15),
                interval: 7
              }} == result
    end

    test "filter to map" do
      {:ok, filter} =
        IntervalFilter.from_map(%{
          "start_date" => "2024-03-01",
          "end_date" => "2024-03-15",
          "interval" => "7"
        })

      assert %{
               start_date: Date.new!(2024, 03, 1),
               end_date: Date.new!(2024, 03, 15),
               interval: 7
             } ==
               IntervalFilter.to_map(filter)
    end
  end
end
