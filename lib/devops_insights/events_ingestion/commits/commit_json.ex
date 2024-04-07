defmodule DevopsInsights.EventsIngestion.Commits.CommitJson do
  alias DevopsInsights.EventsIngestion.Commits.Commit

  @doc """
  Renders a list of commit.
  """
  def index(%{commit: commit}) do
    %{data: for(commit <- commit, do: data(commit))}
  end

  @doc """
  Renders a single commit.
  """
  def show(%{commit: commit}) do
    %{data: data(commit)}
  end

  defp data(%Commit{} = commit) do
    %{
      id: commit.id,
      timestamp: commit.timestamp,
      service_name: commit.service_name
    }
  end
end
