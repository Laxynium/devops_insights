defmodule DevopsInsights.EventsIngestion.Commit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "commits" do
    field :timestamp, :utc_datetime
    field :commit_id, :string
    field :parent_id, :string
    field :properties, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:timestamp, :commit_id, :parent_id, :properties])
    |> validate_required([:timestamp, :commit_id, :parent_id])
  end
end
