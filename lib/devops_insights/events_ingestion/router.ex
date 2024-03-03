defmodule DevopsInsights.EventsIngestion.Router do
  use Phoenix.Router
  get "/deployment-events", DevopsInsights.EventsIngestion.DeploymentEventsController, :get_all
  post "/deployment-events", DevopsInsights.EventsIngestion.DeploymentEventsController, :create
end
