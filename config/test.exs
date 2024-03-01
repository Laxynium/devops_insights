import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :devops_insights, DevopsInsights.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "devops_insights_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :devops_insights, DevopsInsightsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "oLEs0n85hGKAqAG8F4rMX2wvrGZ2YHumgxb7sUZAWsivgdAWQ6mlmbnPJDl4ADqh",
  server: false

# In test we don't send emails.
config :devops_insights, DevopsInsights.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
