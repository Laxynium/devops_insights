defmodule DevopsInsights.EventsIngestion.Deployment do
  @moduledoc false

  alias DevopsInsights.EventsIngestion.Deployment
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "events" do
    field :timestamp, :utc_datetime
    field :serviceName, :string
    field :environment, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deployment, attrs) do
    deployment
    |> cast(attrs, [:timestamp, :serviceName, :environment])
    |> validate_required([:timestamp, :serviceName, :environment])
  end

  @spec in_range?(Deployment.t(), Date.t(), Date.t()) :: boolean()
  def in_range?(%Deployment{timestamp: timestamp}, start, end_) do
    Date.compare(DateTime.to_date(timestamp), start) in [:gt, :eq] &&
      Date.compare(DateTime.to_date(timestamp), end_) in [:lt, :eq]
  end

  @spec calculate_group(Deployment.t(), Date.t(), non_neg_integer()) :: non_neg_integer()
  def calculate_group(%Deployment{timestamp: timestamp}, start, interval_in_days) do
    div(
      Date.diff(DateTime.to_date(timestamp), start),
      interval_in_days
    )
  end

  @spec dimentions_matching?(Deployment.t(), %{}) :: boolean()
  def dimentions_matching?(%Deployment{} = deployment, props) do
    Enum.reduce(
      props,
      true,
      fn {key, value}, acc ->
        acc && (!Map.has_key?(deployment, key) || value === nil || Map.get(deployment, key) === value)
      end
    )
  end
end
