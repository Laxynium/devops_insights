defmodule DevopsInsights.EventsIngestion.Commits.CommitsGatewayTest do
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Commits.CommitsGateway
  use DevopsInsights.DataCase

  describe "initialize service repository" do
    test "creates a root commit for service repository" do
      assert {:ok, %Commit{} = commit} =
               CommitsGateway.create_root_commit(%{
                 "commit_id" => "1",
                 "service_name" => "app-1",
                 "timestamp" => "2024-04-04T19:07:18Z"
               })

      assert %Commit{
               commit_id: "1",
               service_name: "app-1",
               timestamp: ~U[2024-04-04T19:07:18Z],
               parent_id: nil
             } = commit
    end

    test "fails when there is already a root commit for same app" do
      CommitsGateway.create_root_commit(%{
        "commit_id" => "1",
        "service_name" => "app-1",
        "timestamp" => "2024-04-04T19:07:18Z"
      })

      assert {:error, _} =
               CommitsGateway.create_root_commit(%{
                 "commit_id" => "3",
                 "service_name" => "app-1",
                 "timestamp" => "2024-04-04T20:07:18Z"
               })
    end

    test "can insert a commit for another app" do
      CommitsGateway.create_root_commit(%{
        "commit_id" => "1",
        "service_name" => "app-1",
        "timestamp" => "2024-04-04T19:07:18Z"
      })

      assert {:ok, _} =
               CommitsGateway.create_root_commit(%{
                 "commit_id" => "1",
                 "service_name" => "app-2",
                 "timestamp" => "2024-04-04T20:07:18Z"
               })
    end
  end

  test "root commit cannot have a parent" do
    assert {:ok, %Commit{} = commit} =
             CommitsGateway.create_root_commit(%{
               "commit_id" => "1",
               "service_name" => "app-1",
               "timestamp" => "2024-04-04T19:07:18Z",
               "parent_id" => "2"
             })

    assert %Commit{
             commit_id: "1",
             service_name: "app-1",
             timestamp: ~U[2024-04-04T19:07:18Z],
             parent_id: nil
           } = commit
  end
end
