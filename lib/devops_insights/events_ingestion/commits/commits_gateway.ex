defmodule DevopsInsights.EventsIngestion.Commits.CommitsGateway do
  alias Ecto.Changeset
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.Commits.Commit
  import Ecto.Query, only: [from: 2]

  def create_root_commit(attr \\ %{}) do
    commit_changeset = %Commit{} |> Commit.changeset(attr)

    with %Ecto.Changeset{valid?: true} <- commit_changeset do
      service_name = Changeset.fetch_field!(commit_changeset, :service_name)

      any_root =
        Repo.exists?(
          from c in "commits",
            where: is_nil(c.parent_id) and c.service_name == ^service_name
        )

      if(any_root == true) do
        {:error,
         commit_changeset
         |> Changeset.add_error(
           :commit,
           "there is already a root commit for this service_name"
         )}
        |> IO.inspect()
      else
        handle_commit_insertion(attr)
      end
    else
      _ -> {:error, commit_changeset} |> IO.inspect()
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
