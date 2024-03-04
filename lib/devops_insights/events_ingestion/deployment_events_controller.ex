defmodule DevopsInsights.EventsIngestion.DeploymentEventsController do
  alias DevopsInsights.EventsIngestion.Event
  use Phoenix.Controller, formats: [:json]
  import Plug.Conn

  @spec get_all(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def get_all(conn, _params) do
    conn
    |> json(DevopsInsights.EventsIngestion.EventsStore.find_all())
  end

  @spec create(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def create(
        conn,
        %{
          "timestamp" => timestamp,
          "serviceName" => serviceName,
          "environment" => environment
        }
      ) do
    case Event.create_deployment(timestamp, serviceName, environment) do
      {:ok, event} ->
        DevopsInsights.EventsIngestion.EventsStore.add(event)

        conn
        |> put_status(:created)
        |> json(Map.from_struct(event))

      {:error, %{reason: reason}} ->
        conn
        |> put_status(400)
        |> json(%{reason: reason})
    end
  end
end
