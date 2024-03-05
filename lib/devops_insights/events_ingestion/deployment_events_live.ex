defmodule DevopsInsights.EventsIngestion.DeploymentEventsLive do
  require Logger
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("Sending a msg to itself...")
    Process.send_after(self(), :work, 5_000)

    {:ok,
     socket
     |> assign(:items, fetch_formated_events())
     |> assign(:pid, "#{inspect(self())}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1><%= @pid %></h1>

    <ul>
      <%= for item <- @items do %>
        <li><%= item %></li>
      <% end %>
    </ul>
    """
  end

  @impl true
  def handle_event(_event, _unsigned_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(_any, socket) do
    Logger.info("Updating a deployment events...")
    {:noreply, socket |> assign(:items, fetch_formated_events())}
  end

  defp fetch_formated_events() do
    DevopsInsights.EventsIngestion.EventsStore.find_all()
    |> Enum.map(
      &(&1.timestamp
        |> DateTime.to_string())
    )
  end
end
