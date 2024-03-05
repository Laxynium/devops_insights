defmodule DevopsInsights.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DevopsInsightsWeb.Telemetry,
      DevopsInsights.Repo,
      {DNSCluster, query: Application.get_env(:devops_insights, :dns_cluster_query) || :ignore},
      # {Phoenix.PubSub, name: DevopsInsights.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DevopsInsights.Finch},
      # Start a worker by calling: DevopsInsights.Worker.start_link(arg)
      # {DevopsInsights.Worker, arg},
      # Start to serve requests, typically the last entry
      DevopsInsightsWeb.Endpoint,
      DevopsInsights.EventsIngestion.EventsStore
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DevopsInsights.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DevopsInsightsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
