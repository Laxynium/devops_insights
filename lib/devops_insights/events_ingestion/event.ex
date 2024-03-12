defmodule DevopsInsights.EventsIngestion.Event do
  @moduledoc false

  alias DevopsInsights.EventsIngestion.Event
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "events" do
    field :timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:deployment]
    field :serviceName, :string
    field :environment, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :timestamp, :serviceName, :environment])
    |> validate_required([:type, :timestamp, :serviceName, :environment])
  end

  @spec in_range?(Event.t(), Date.t(), Date.t()) :: boolean()
  def in_range?(%Event{timestamp: timestamp}, start, end_) do
    Date.compare(DateTime.to_date(timestamp), start) in [:gt, :eq] &&
      Date.compare(DateTime.to_date(timestamp), end_) in [:lt, :eq]
  end

  @spec calculate_group(Event.t(), Date.t(), non_neg_integer()) :: non_neg_integer()
  def calculate_group(%Event{timestamp: timestamp}, start, interval_in_days) do
    div(
      Date.diff(DateTime.to_date(timestamp), start),
      interval_in_days
    )
  end

  @spec dimentions_matching?(Event.t(), %{}) :: boolean()
  def dimentions_matching?(%Event{} = event, props) do
    Enum.reduce(
      props,
      true,
      fn {key, value}, acc ->
        acc && (!Map.has_key?(event, key) || Map.get(event, key) === value)
      end
    )
  end
end
