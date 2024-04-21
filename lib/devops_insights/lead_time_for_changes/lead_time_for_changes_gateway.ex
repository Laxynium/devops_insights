defmodule DevopsInsights.LeadTimeForChanges.LeadTimeForChangesGateway do
  alias DevopsInsights.EventsIngestion.Deployments.Deployment
  alias DevopsInsights.Repo
  alias DevopsInsights.EventsIngestion.IntervalFilter

  def get_lead_time_for_changes_metric(
        %IntervalFilter{start_date: start_date, end_date: end_date, interval: interval},
        dimensions \\ []
      ) do
  end
end
