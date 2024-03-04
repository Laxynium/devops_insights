defmodule DevopsInsights.EventsIngestion.EventsTest do
  require Logger
  alias DevopsInsights.EventsIngestion.EventsStore
  use DevopsInsightsWeb.ConnCase

  test "Ingest a deployment event", %{conn: conn} do
    conn =
      post(conn, ~p"/api/deployment-events", %{
        timestamp: "2016-05-24T13:26:08Z",
        serviceName: "app-1",
        environment: "prod"
      })

    assert response =
             %{
               "id" => _,
               "timestamp" => "2016-05-24T13:26:08Z",
               "serviceName" => "app-1",
               "environment" => "prod",
               "type" => "deployment"
             } = json_response(conn, 201)

    assert EventsStore.find_all() |> Enum.any?(&(&1.id == response["id"]))
  end

  test "Deployment event ingestion fails when serviceName is empty", %{conn: conn} do
    conn =
      post(conn, ~p"/api/deployment-events", %{
        timestamp: "2016-05-24T13:26:08Z",
        serviceName: "",
        environment: "prod"
      })

    assert %{
             "reason" => "Invalid serviceName"
           } = json_response(conn, 400)
  end

  test "Deployment event ingestion fails when environment is empty", %{conn: conn} do
    conn =
      post(conn, ~p"/api/deployment-events", %{
        timestamp: "2016-05-24T13:26:08Z",
        serviceName: "app-1",
        environment: ""
      })

    assert %{
             "reason" => "Invalid environment"
           } = json_response(conn, 400)
  end

  test "Deployment event ingestion fails when timestamp is empty", %{conn: conn} do
    conn =
      post(conn, ~p"/api/deployment-events", %{
        timestamp: "",
        serviceName: "app-1",
        environment: ""
      })

    assert %{
             "reason" => "Invalid timestamp"
           } = json_response(conn, 400)
  end

  test "Deployment event ingestion fails when timestamp is not a string", %{conn: conn} do
    conn =
      post(conn, ~p"/api/deployment-events", %{
        timestamp: 1_234_567_890,
        serviceName: "app-1",
        environment: ""
      })

    assert %{
             "reason" => "Invalid timestamp"
           } = json_response(conn, 400)
  end
end
