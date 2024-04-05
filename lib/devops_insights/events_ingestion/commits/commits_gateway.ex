defmodule DevopsInsights.EventsIngestion.Commits.CommitsGateway do
  alias DevopsInsights.EventsIngestion.Commits.VersionControlRepository
  alias Ecto.Changeset
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.Commits.Commit

  def create_root_commit(attr \\ %{}) do
    commit =
      %Commit{}
      |> Commit.changeset(attr)

    insert_result =
      commit
      |> Commit.changeset(attr)
      |> Repo.insert()

    with {:ok, %Commit{} = commit} <- insert_result do
      Endpoint.broadcast("commits", "commit_ingested", commit)
    end

    insert_result
  end
end
