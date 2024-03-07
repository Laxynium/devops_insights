defmodule DevopsInsights.EventsIngestionTest do
  use DevopsInsights.DataCase

  alias DevopsInsights.EventsIngestion

  describe "events" do
    alias DevopsInsights.EventsIngestion.Event

    import DevopsInsights.EventsIngestionFixtures

    @invalid_attrs %{timestamp: nil, type: nil, serviceName: nil, environmnet: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert EventsIngestion.list_events() == [event]
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        timestamp: ~U[2024-03-06 22:39:00Z],
        type: :deployment,
        serviceName: "some serviceName",
        environmnet: "some environmnet"
      }

      assert {:ok, %Event{} = event} = EventsIngestion.create_event(valid_attrs)
      assert event.timestamp == ~U[2024-03-06 22:39:00Z]
      assert event.type == :deployment
      assert event.serviceName == "some serviceName"
      assert event.environmnet == "some environmnet"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = EventsIngestion.create_event(@invalid_attrs)
    end
  end
end
