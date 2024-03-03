defmodule DevopsInsightsWeb.Router do
  use DevopsInsightsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    forward "/", DevopsInsights.EventsIngestion.Router
  end
end
