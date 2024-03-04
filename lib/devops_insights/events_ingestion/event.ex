defmodule DevopsInsights.EventsIngestion.Event do
  @moduledoc false
  alias Ecto.UUID
  alias DevopsInsights.EventsIngestion.Event
  @enforce_keys [:id, :type, :timestamp, :serviceName, :environment]
  defstruct [:id, :type, :timestamp, :serviceName, :environment]

  @type t() :: %Event{
          id: String.t(),
          type: atom(),
          timestamp: DateTime.t(),
          serviceName: String.t(),
          environment: String.t()
        }

  @spec create_deployment(String.t() | integer, String.t(), String.t()) ::
          {:ok, DevopsInsights.EventsIngestion.Event.t()}
          | {:error, %{reason: String.t()}}
  def create_deployment(timestamp, serviceName, environment) do
    with {:ok, timestamp} <- parseTimestamp(timestamp),
         {:ok, serviceName} <- parseServiceName(serviceName),
         {:ok, environment} <- parseEnvironment(environment) do
      {:ok,
       %Event{
         id: UUID.generate(),
         type: :deployment,
         timestamp: timestamp,
         serviceName: serviceName,
         environment: environment
       }}
    else
      {:error, %{reason: reason}} -> {:error, %{reason: reason}}
    end
  end

  def parseTimestamp(timestamp) when is_binary(timestamp) do
    with {:ok, timestamp, _} <- DateTime.from_iso8601(timestamp, Calendar.ISO) do
      {:ok, timestamp}
    else
      _err -> {:error, %{reason: "Invalid timestamp"}}
    end
  end

  def parseTimestamp(_timestamp) do
    {:error, %{reason: "Invalid timestamp"}}
  end

  def parseServiceName(serviceName) do
    if String.length(serviceName) < 1 do
      {:error, %{reason: "Invalid serviceName"}}
    else
      {:ok, serviceName}
    end
  end

  def parseEnvironment(environment) do
    if String.length(environment) < 1,
      do: {:error, %{reason: "Invalid environment"}},
      else: {:ok, environment}
  end
end
