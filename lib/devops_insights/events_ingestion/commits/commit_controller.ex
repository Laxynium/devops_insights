defmodule DevopsInsights.EventsIngestion.Commits.CommitController do
  alias DevopsInsights.EventsIngestion.Commits.CommitsGateway
  alias DevopsInsights.EventsIngestion.Commits.Commit
  use DevopsInsightsWeb, :controller

  action_fallback DevopsInsightsWeb.FallbackController

  def create_root_commit(conn, %{"commit" => commit_params}) do
    with {:ok, %Commit{} = commit} <-
           CommitsGateway.create_root_commit(commit_params) do
      conn
      |> json(%{data: %{}})
    end
  end

  def show(conn, %{"id" => id}) do
    %{}
  end
end
