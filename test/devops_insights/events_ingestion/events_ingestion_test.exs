defmodule DevopsInsights.EventsIngestion.EventsIngestionTest do
  alias DevopsInsights.EventsIngestion.Event
  use DevopsInsights.DataCase

  alias DevopsInsights.EventsIngestion.Gateway

  describe "events" do
    alias DevopsInsights.EventsIngestion.Event

    import DevopsInsights.EventsIngestionFixtures

    @invalid_attrs %{timestamp: nil, type: nil, serviceName: nil, environmnet: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Gateway.list_events() == [event]
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{
        timestamp: ~U[2024-03-06 22:39:00Z],
        type: :deployment,
        serviceName: "some serviceName",
        environmnet: "some environmnet"
      }

      assert {:ok, %Event{} = event} = Gateway.create_event(valid_attrs)
      assert event.timestamp == ~U[2024-03-06 22:39:00Z]
      assert event.type == :deployment
      assert event.serviceName == "some serviceName"
      assert event.environmnet == "some environmnet"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gateway.create_event(@invalid_attrs)
    end

    test "split_events_into_time_intervals" do
      [
        an_event(~U[2024-01-14 23:59:59Z]),
        an_event(~U[2024-01-15 00:00:00Z]),
        an_event(~U[2024-01-15 12:30:00Z]),
        an_event(~U[2024-01-15 23:59:59Z]),
        an_event(~U[2024-01-16 00:00:00Z])
      ]
      |> Enum.each(&Gateway.create_event(&1))

      assert [%{count: 3, group: 0}] == Gateway.list_events(~D[2024-01-15], ~D[2024-01-15], 1)
    end

    test "split_events_into_time_intervals_mulitple_days" do
      [
        an_event(~U[2024-01-14 23:59:59Z]),
        an_event(~U[2024-01-15 00:00:00Z]),
        an_event(~U[2024-01-15 12:30:00Z]),
        an_event(~U[2024-01-15 23:59:59Z]),
        an_event(~U[2024-01-16 00:00:00Z])
      ]
      |> Enum.each(&Gateway.create_event(&1))

      assert [%{count: 1, group: 0}, %{count: 3, group: 1}, %{count: 1, group: 2}] ==
               Gateway.list_events(~D[2024-01-14], ~D[2024-01-16], 1)
    end

    test "split_events_into_time_intervals_interval > 1" do
      [
        an_event(~U[2024-01-14 23:59:59Z]),
        an_event(~U[2024-01-15 00:00:00Z]),
        an_event(~U[2024-01-15 12:30:00Z]),
        an_event(~U[2024-01-15 23:59:59Z]),
        an_event(~U[2024-01-16 00:00:00Z])
      ]
      |> Enum.each(&Gateway.create_event(&1))

      assert [%{count: 5, group: 0}] ==
               Gateway.list_events(~D[2024-01-14], ~D[2024-01-16], 3)
    end
  end

  defp an_event(timestamp) do
    %{
      timestamp: timestamp,
      type: :deployment,
      serviceName: "devops_insights",
      environmnet: "prod"
    }
  end
end
