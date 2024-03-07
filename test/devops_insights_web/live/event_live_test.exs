defmodule DevopsInsightsWeb.EventLiveTest do
  use DevopsInsightsWeb.ConnCase

  import Phoenix.LiveViewTest
  import DevopsInsights.EventsIngestionFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_event(_) do
    event = event_fixture()
    %{event: event}
  end

  describe "Index" do
    setup [:create_event]

    test "lists all events", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/events")

      assert html =~ "Listing Events"
    end
  end
end
