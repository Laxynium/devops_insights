defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesMetricTest do
  alias MetricFixtures
  use DevopsInsights.DataCase

  test "no deployments single commit" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert {:error, "No deployments yet"} = MetricFixtures.get_lead_time_for_changes_metric()
  end

  test "single deployment single commit" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :deploy, commit_id: "1", timestamp: "2024-04-04T19:10:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert {:ok, 600} = MetricFixtures.get_lead_time_for_changes_metric()
  end

  test "each commit is deployed" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :deploy, commit_id: "1", timestamp: "2024-04-04T19:12:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert {:ok, 660} = MetricFixtures.get_lead_time_for_changes_metric()
  end

  test "commits gap between deployments" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert {:ok, 900} = MetricFixtures.get_lead_time_for_changes_metric()
  end

  test "deploy each second commit" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-04T19:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-04T19:10:00Z"},
      %{type: :commit, commit_id: "3", parent_id: "2", timestamp: "2024-04-04T19:15:00Z"},
      %{type: :deploy, commit_id: "2", timestamp: "2024-04-04T19:20:00Z"},
      %{type: :commit, commit_id: "4", parent_id: "3", timestamp: "2024-04-04T19:30:00Z"},
      %{type: :commit, commit_id: "5", parent_id: "4", timestamp: "2024-04-04T19:35:00Z"},
      %{type: :deploy, commit_id: "5", timestamp: "2024-04-04T19:40:00Z"}
    ]
    |> MetricFixtures.apply_events()

    assert {:ok, 600} = MetricFixtures.get_lead_time_for_changes_metric()
  end

  @tag only_me: true
  test "deploys outside a time range are not included" do
    [
      %{type: :commit, commit_id: "1", parent_id: nil, timestamp: "2024-04-01T12:00:00Z"},
      %{type: :commit, commit_id: "2", parent_id: "1", timestamp: "2024-04-02T12:00:00Z"},
      %{type: :commit, commit_id: "3", parent_id: "2", timestamp: "2024-04-03T12:00:00Z"},
      %{type: :deploy, commit_id: "3", timestamp: "2024-04-04T12:00:00Z"},
      %{type: :commit, commit_id: "4", parent_id: "3", timestamp: "2024-04-05T12:00:00Z"},
      %{type: :commit, commit_id: "5", parent_id: "4", timestamp: "2024-04-06T12:00:00Z"},
      %{type: :deploy, commit_id: "5", timestamp: "2024-04-07T12:00:00Z"}
    ]
    |> MetricFixtures.apply_events()

    # (2 + 1)/2 * 24 * 60 * 60
    assert {:ok, 129_600} =
             MetricFixtures.get_lead_time_for_changes_metric(~D[2024-04-06], ~D[2030-04-08])
  end
end
