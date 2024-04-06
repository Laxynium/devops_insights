defmodule DevopsInsights.EventsIngestion.Commits.CommitsGateway do
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.Commits.Commit
  import Ecto.Query, only: [from: 2]

  def create_root_commit(attr \\ %{}) do
    service_name = Map.get(attr, "service_name")

    any_root =
      Repo.exists?(
        from c in "commits",
          where: is_nil(c.parent_id) and c.service_name == ^service_name
      )

    if(any_root == true) do
      {:error, "There is already a root commit"}
    else
      handle_commit_insertion(attr)
    end
  end

  defp handle_commit_insertion(attr) do
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
