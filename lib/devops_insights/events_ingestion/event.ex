defmodule DevopsInsights.EventsIngestion.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
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
end
