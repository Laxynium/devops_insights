defmodule DevopsInsightsWeb.Router do
  use DevopsInsightsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end
end
