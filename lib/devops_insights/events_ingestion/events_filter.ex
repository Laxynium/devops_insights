defmodule DevopsInsights.EventsIngestion.EventsFilter do
  @type t() :: %__MODULE__{
          start_date: Date.t(),
          end_date: Date.t(),
          interval: non_neg_integer()
        }
  @enforce_keys [:start_date, :end_date, :interval]
  defstruct [:start_date, :end_date, :interval]

  @spec from_map(%{String.t() => String.t()}) :: Result.t(any(), t())
  def from_map(%{
        "start_date" => start_date_str,
        "end_date" => end_date_str,
        "interval" => interval_str
      }) do
    with {:ok, start_date} when is_binary(start_date_str) <- Date.from_iso8601(start_date_str),
         {:ok, end_date} when is_binary(end_date_str) <- Date.from_iso8601(end_date_str),
         {interval, _} when is_binary(interval_str) <- Integer.parse(interval_str) do
      Result.Ok.of(%__MODULE__{
        start_date: start_date,
        end_date: end_date,
        interval: interval
      })
    else
      error -> Result.Error.of(error)
    end
  end

  @spec to_map(t()) :: %{start_date: Date.t(), end_date: Date.t(), interval: non_neg_integer()}
  def to_map(events_filter) do
    Map.from_struct(events_filter)
  end
end
