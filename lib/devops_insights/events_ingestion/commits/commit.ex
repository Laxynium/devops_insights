defmodule DevopsInsights.EventsIngestion.Commits.Commit do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "commits" do
    field :timestamp, :utc_datetime
    field :commit_id, :string
    field :parent_id, :string
    field :service_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:timestamp, :commit_id, :parent_id, :service_name])
    |> unique_constraint([:commit_id, :service_name])
    |> validate_required([:timestamp, :commit_id, :service_name])
  end
end
