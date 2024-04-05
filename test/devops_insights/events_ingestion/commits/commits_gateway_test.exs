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
  end

  test "" do
  end
end
