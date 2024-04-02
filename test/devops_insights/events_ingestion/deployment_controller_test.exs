defmodule DevopsInsights.EventsIngestion.DeploymentControllerTest do
  use DevopsInsightsWeb.ConnCase

  @create_attrs %{
    timestamp: ~U[2024-03-06 22:39:00Z],
    serviceName: "some serviceName",
    environment: "some environment"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all deployments", %{conn: conn} do
      conn = get(conn, ~p"/api/deployments")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create deployment" do
    test "renders deployment when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/deployments", event: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/deployments/#{id}")

      assert %{
               "id" => ^id,
               "environment" => "some environment",
               "serviceName" => "some serviceName",
               "timestamp" => "2024-03-06T22:39:00Z",
             } = json_response(conn, 200)["data"]
    end
  end
end
