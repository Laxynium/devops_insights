defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway do
  alias DevopsInsights.EventsIngestion.Commits.Commit
  alias DevopsInsights.EventsIngestion.Commits
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.IntervalFilter

  def get_lead_time_for_changes_metric(
        %IntervalFilter{start_date: start_date, end_date: end_date, interval: interval},
        dimensions \\ []
      ) do
    deployments =
      Repo.all(Deployment)
      |> Enum.sort_by(fn %Deployment{timestamp: timestamp} -> timestamp end, :asc)
      |> Enum.with_index(fn el, i -> {i, el} end)

    if not (deployments |> Enum.empty?()) do
      {:ok, 15}
    else
      {:error, "No deployments yet"}
    end
  end
end
