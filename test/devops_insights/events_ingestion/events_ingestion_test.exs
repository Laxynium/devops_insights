defmodule DevopsInsights.EventsIngestion.EventsIngestionTest do
  alias DevopsInsights.EventsIngestion.Event
  use DevopsInsights.DataCase

  alias DevopsInsights.EventsIngestion.Gateway

  describe "events" do
    alias DevopsInsights.EventsIngestion.Event

    import DevopsInsights.EventsIngestionFixtures

    @invalid_attrs %{timestamp: nil, type: nil, serviceName: nil, environment: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Gateway.list_events() == [event]
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        timestamp: ~U[2024-03-06 22:39:00Z],
        serviceName: "some serviceName",
        environment: "some environment"
      }

      assert {:ok, %Event{} = event} = Gateway.create_event(valid_attrs)
      assert event.timestamp == ~U[2024-03-06 22:39:00Z]
      assert event.serviceName == "some serviceName"
      assert event.environment == "some environment"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gateway.create_event(@invalid_attrs)
    end
  end
end
