defmodule DevopsInsights.EventsIngestion.Event do
  @moduledoc false

  alias DevopsInsights.EventsIngestion.Event
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "events" do
    field :timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:deployment]
    field :serviceName, :string
    field :environmnet, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :timestamp, :serviceName, :environmnet])
    |> validate_required([:type, :timestamp, :serviceName, :environmnet])
  end

  @spec in_range?(Event.t(), Date.t(), Date.t()) :: boolean()
  def in_range?(%Event{timestamp: timestamp}, start, end_) do
    start <= DateTime.to_date(timestamp) &&
      DateTime.to_date(timestamp) <= end_
  end

  @spec calculate_group(Event.t(), Date.t(), non_neg_integer()) :: non_neg_integer()
  def calculate_group(%Event{timestamp: timestamp}, start, interval_in_days) do
    div(
      Date.diff(DateTime.to_date(timestamp), start),
      interval_in_days
    )
  end
end
