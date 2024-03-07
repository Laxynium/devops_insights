defmodule DevopsInsightsWeb.EventJSON do
  alias DevopsInsights.EventsIngestion.Event

  @doc """
  Renders a list of events.
  """
  def index(%{events: events}) do
    %{data: for(event <- events, do: data(event))}
  end

  @doc """
  Renders a single event.
  """
  def show(%{event: event}) do
    %{data: data(event)}
  end

  defp data(%Event{} = event) do
    %{
      id: event.id,
      type: event.type,
      timestamp: event.timestamp,
      serviceName: event.serviceName,
      environmnet: event.environmnet
    }
  end
end
