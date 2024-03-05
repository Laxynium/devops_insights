defmodule DevopsInsightsWeb.Router do
  alias DevopsInsights.EventsIngestion
  use DevopsInsightsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live "/events", EventsIngestion.DeploymentEventsLive
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    forward "/", DevopsInsights.EventsIngestion.Router
  end
end
