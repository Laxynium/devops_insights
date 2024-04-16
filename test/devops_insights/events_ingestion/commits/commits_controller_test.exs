defmodule DevopsInsights.EventsIngestion.Commits.CommitsControllerTest do
  use DevopsInsightsWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "should insert root commit", %{conn: conn} do
    conn =
      post(conn, ~p"/api/commits/root",
        commit: %{
          commit_id: "1",
          service_name: "some serviceName",
          timestamp: ~U[2024-03-06 22:39:00Z]
        }
      )

    assert %{"id" => _} = json_response(conn, 201)["data"]
  end

  test "should insert commit", %{conn: conn} do
    post(conn, ~p"/api/commits/root",
      commit: %{
        commit_id: "1",
        service_name: "some serviceName",
        timestamp: ~U[2024-03-06 22:39:00Z]
      }
    )

    assert %{"id" => _} =
             (post(conn, ~p"/api/commits",
                commit: %{
                  commit_id: "2",
                  parent_id: "1",
                  service_name: "some serviceName",
                  timestamp: ~U[2024-03-06 22:39:00Z]
                }
              )
              |> json_response(201))["data"]
  end
end
