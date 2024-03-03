defmodule DevopsInsights.EventsIngestion.EventsStore do
  @moduledoc false
  alias DevopsInsights.EventsIngestion.Event
  use Agent

  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @spec add(Event.t()) :: :ok
  def add(event) do
    Agent.update(__MODULE__, fn events -> [event | events] end)
  end

  @spec find_all() :: list(Event.t())
  def find_all() do
    Agent.get(__MODULE__, & &1)
    |> Enum.map(&Map.from_struct(&1))
  end
end
