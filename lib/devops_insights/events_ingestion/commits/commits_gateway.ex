defmodule DevopsInsights.EventsIngestion.Commits.CommitsGateway do
  @moduledoc false
  alias Ecto.Changeset
  alias DevopsInsightsWeb.Endpoint
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.Commits.Commit
  import Ecto.Query, only: [from: 2]

  def create_commit(attr \\ %{}) do
    with %Ecto.Changeset{valid?: true} = commit_changeset <-
           Commit.changeset(%Commit{}, attr),
         {:ok} <- parent_exists?(commit_changeset) do
      handle_commit_insertion(commit_changeset)
    else
      invalid_changeset -> {:error, invalid_changeset}
    end
  end

  def create_root_commit(attr \\ %{}) do
    with %Ecto.Changeset{valid?: true} = commit_changeset <-
           Commit.changeset(
             %Commit{},
             attr |> Map.drop(["parent_id"])
           ),
         {:ok} <- root_do_not_exist?(commit_changeset) do
      handle_commit_insertion(commit_changeset)
    else
      invalid_changeset -> {:error, invalid_changeset}
    end
  end

  defp root_do_not_exist?(commit_changeset) do
    service_name = Changeset.fetch_field!(commit_changeset, :service_name)

    case Repo.exists?(
           from c in "commits",
             where: is_nil(c.parent_id) and c.service_name == ^service_name
         ) do
      true ->
        commit_changeset
        |> Changeset.add_error(
          :commit,
          "there is already a root commit for #{service_name}"
        )

      false ->
        {:ok}
    end
  end

  defp handle_commit_insertion(commit) do
    insert_result =
      commit
      |> Repo.insert()

    with {:ok, %Commit{} = commit} <- insert_result do
      Endpoint.broadcast("commits", "commit_ingested", commit)
    end

    insert_result
  end

  defp parent_exists?(commit_changeset) do
    parent_id = Changeset.fetch_field!(commit_changeset, :parent_id)
    service_name = Changeset.fetch_field!(commit_changeset, :service_name)

    case Repo.exists?(
           from c in "commits",
             where: c.commit_id == ^parent_id and c.service_name == ^service_name
         ) do
      true ->
        {:ok}

      false ->
        commit_changeset
        |> Changeset.add_error(
          :commit,
          "Parent commit #{parent_id} was not found for #{service_name}"
        )
    end
  end
end
