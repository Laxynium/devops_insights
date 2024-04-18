defmodule DevopsInsightsWeb.Router do
  use DevopsInsightsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DevopsInsightsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DevopsInsightsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", DevopsInsights do
    pipe_through :browser

    live "/deployment-frequency", DeploymentFrequency.Live.Index, :index
    live "/lead-time-for-changes", LeadTimeForChanges.Live.Index, :index
  end

  scope "/api", DevopsInsights do
    pipe_through :api

    resources "/deployments", EventsIngestion.Deployments.DeploymentController,
      except: [:new, :edit]

    post "/commits/root", EventsIngestion.Commits.CommitController, :create_root_commit
    post "/commits", EventsIngestion.Commits.CommitController, :create_commit
    get "/commits/:id", EventsIngestion.Commits.CommitController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:devops_insights, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DevopsInsightsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
