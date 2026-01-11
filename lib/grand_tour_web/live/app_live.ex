defmodule GrandTourWeb.AppLive do
  use GrandTourWeb, :live_view

  alias GrandTour.Tours

  @impl true
  def mount(_params, _session, socket) do
    mapbox_token = Application.get_env(:grand_tour, :mapbox)[:access_token]

    {:ok,
     socket
     |> assign(:mapbox_token, mapbox_token)
     |> assign(:active_tab, :overview)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    scope = socket.assigns.current_scope
    tour = Tours.get_tour!(scope, id)
    trips = Tours.list_trips(tour)

    socket
    |> assign(:page_title, tour.name)
    |> assign(:tour, tour)
    |> assign(:trips, trips)
    |> assign(:trip, nil)
  end

  defp apply_action(socket, :new_trip, %{"id" => id}) do
    scope = socket.assigns.current_scope
    tour = Tours.get_tour!(scope, id)
    trips = Tours.list_trips(tour)

    socket
    |> assign(:page_title, "New Trip")
    |> assign(:tour, tour)
    |> assign(:trips, trips)
    |> assign(:trip, %Tours.Trip{})
  end

  defp apply_action(socket, :edit_trip, %{"id" => id, "trip_id" => trip_id}) do
    scope = socket.assigns.current_scope
    tour = Tours.get_tour!(scope, id)
    trips = Tours.list_trips(tour)
    trip = Tours.get_trip!(trip_id)

    socket
    |> assign(:page_title, "Edit Trip")
    |> assign(:tour, tour)
    |> assign(:trips, trips)
    |> assign(:trip, trip)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      tour_title={@tour.name}
      tour_id={@tour.id}
    >
      <div id="app-container" class="flex flex-col h-[calc(100vh-4rem)]">
        <%!-- Navigation Tabs --%>
        <nav class="flex items-center border-b border-base-300 px-4 flex-shrink-0 h-12">
          <%!-- Left: Back to Tours --%>
          <.link navigate={~p"/tours"} class="tab">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Tours
          </.link>

          <%!-- Center: Tabs --%>
          <div class="tabs tabs-border flex-1">
            <button
              phx-click="switch_tab"
              phx-value-tab="overview"
              class={["tab", @active_tab == :overview && "tab-active"]}
            >
              <.icon name="hero-globe-alt" class="w-4 h-4 mr-2" /> Overview
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="trips"
              class={["tab", @active_tab == :trips && "tab-active"]}
            >
              <.icon name="hero-map" class="w-4 h-4 mr-2" /> Trips
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="timeline"
              class={["tab", @active_tab == :timeline && "tab-active"]}
            >
              <.icon name="hero-calendar" class="w-4 h-4 mr-2" /> Timeline
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="documents"
              class={["tab", @active_tab == :documents && "tab-active"]}
            >
              <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> Documents
            </button>
          </div>
        </nav>

        <%!-- Split View Container --%>
        <div class="flex flex-1 overflow-hidden flex-col lg:flex-row">
          <%!-- Map Panel (left on desktop, top on mobile) --%>
          <div
            id="map-panel"
            class="w-full lg:w-1/2 h-1/2 lg:h-full bg-base-200 relative"
            phx-update="ignore"
          >
            <div
              id="map-container"
              class="absolute inset-0 w-full h-full"
              phx-hook="MapHook"
              data-mapbox-token={@mapbox_token}
              data-lng="20"
              data-lat="20"
              data-zoom="1.8"
            >
            </div>
          </div>

          <%!-- Resizable Divider --%>
          <div
            id="divider"
            class="hidden lg:flex w-1 bg-base-300 hover:bg-primary cursor-col-resize items-center justify-center group"
            phx-hook="ResizeDivider"
          >
            <div class="w-0.5 h-8 bg-base-content/20 group-hover:bg-primary-content/50 rounded-full">
            </div>
          </div>

          <%!-- Content Panel (right on desktop, bottom on mobile) --%>
          <div id="content-panel" class="w-full lg:w-1/2 h-1/2 lg:h-full overflow-auto bg-base-100">
            <div class="p-6">
              <.tab_content
                tab={@active_tab}
                tour={@tour}
                trips={@trips}
                live_action={@live_action}
                trip={@trip}
              />
            </div>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new_trip, :edit_trip]}
        id="trip-modal"
        show
        on_cancel={JS.patch(~p"/tours/#{@tour}")}
      >
        <.live_component
          module={GrandTourWeb.TripLive.FormComponent}
          id={@trip.id || :new}
          title={@page_title}
          action={@live_action}
          trip={@trip}
          tour={@tour}
          patch={~p"/tours/#{@tour}"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  # Tab content components
  attr :tab, :atom, required: true
  attr :tour, :map, required: true
  attr :trips, :list, required: true
  attr :live_action, :atom, required: true
  attr :trip, :map

  defp tab_content(%{tab: :overview} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <div class="flex items-start justify-between">
        <div>
          <h1 class="mb-2 text-3xl">{@tour.name}</h1>
          <p :if={@tour.subtitle} class="lead text-lg text-base-content/70 mt-0">
            {@tour.subtitle}
          </p>
        </div>
        <span class={[
          "badge",
          @tour.is_public && "badge-success",
          !@tour.is_public && "badge-ghost"
        ]}>
          {if @tour.is_public, do: "Public", else: "Private"}
        </span>
      </div>

      <div class="stats stats-vertical lg:stats-horizontal w-full mt-6 border border-base-300 rounded">
        <div class="stat">
          <div class="stat-title">Trips</div>
          <div class="stat-value">{length(@trips)}</div>
          <div class="stat-desc">Planned segments</div>
        </div>
        <div class="stat">
          <div class="stat-title">Status</div>
          <div class="stat-value text-lg">
            {status_summary(@trips)}
          </div>
          <div class="stat-desc">Overall progress</div>
        </div>
        <div class="stat">
          <div class="stat-title">Created</div>
          <div class="stat-value text-lg">
            {Calendar.strftime(@tour.inserted_at, "%b %Y")}
          </div>
          <div class="stat-desc">Last updated {Calendar.strftime(@tour.updated_at, "%b %d")}</div>
        </div>
      </div>
    </div>
    """
  end

  defp tab_content(%{tab: :trips} = assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h1 class="text-2xl font-bold">Trips</h1>
        <.link patch={~p"/tours/#{@tour}/trips/new"} class="btn btn-primary btn-sm">
          <.icon name="hero-plus" class="w-4 h-4" /> Add Trip
        </.link>
      </div>

      <div :if={@trips == []} class="text-center py-12 text-base-content/60">
        <.icon name="hero-map" class="w-12 h-12 mx-auto mb-4 opacity-50" />
        <p>No trips yet. Add your first trip to get started.</p>
      </div>

      <div :if={@trips != []} class="space-y-3">
        <div
          :for={trip <- @trips}
          id={"trip-#{trip.id}"}
          class="card card-compact bg-base-200 hover:bg-base-300 transition-colors rounded border border-base-300"
        >
          <div class="card-body flex-row items-center gap-4">
            <div class="badge badge-lg badge-ghost font-mono">{trip.position}</div>
            <div class="flex-1 min-w-0">
              <h3 class="font-semibold truncate">{trip.name}</h3>
              <p :if={trip.subtitle} class="text-sm text-base-content/60 truncate">
                {trip.subtitle}
              </p>
              <div class="flex gap-2 mt-1">
                <span class={["badge badge-sm", status_badge_class(trip.status)]}>
                  {trip.status || "planning"}
                </span>
                <span :if={trip.start_date} class="text-xs text-base-content/50">
                  {format_date_range(trip.start_date, trip.end_date)}
                </span>
              </div>
            </div>
            <div class="flex gap-1">
              <button
                :if={trip.position > 1}
                phx-click="move_trip"
                phx-value-id={trip.id}
                phx-value-direction="up"
                class="btn btn-ghost btn-xs btn-square"
                title="Move up"
              >
                <.icon name="hero-chevron-up" class="w-4 h-4" />
              </button>
              <button
                :if={trip.position < length(@trips)}
                phx-click="move_trip"
                phx-value-id={trip.id}
                phx-value-direction="down"
                class="btn btn-ghost btn-xs btn-square"
                title="Move down"
              >
                <.icon name="hero-chevron-down" class="w-4 h-4" />
              </button>
              <.link
                patch={~p"/tours/#{@tour}/trips/#{trip}/edit"}
                class="btn btn-ghost btn-xs btn-square"
              >
                <.icon name="hero-pencil" class="w-4 h-4" />
              </.link>
              <button
                phx-click="delete_trip"
                phx-value-id={trip.id}
                data-confirm="Delete this trip?"
                class="btn btn-ghost btn-xs btn-square text-error"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp tab_content(%{tab: :timeline} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <h1>Timeline</h1>
      <p class="text-base-content/70">
        Visual timeline of your journey will appear here.
      </p>
      <div class="alert alert-info mt-4 rounded">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>Timeline view coming soon</span>
      </div>
    </div>
    """
  end

  defp tab_content(%{tab: :documents} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <h1>Documents</h1>
      <p class="text-base-content/70">
        Your trip notes and documentation will appear here.
      </p>
      <div class="alert alert-info mt-4 rounded">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>Document management coming soon</span>
      </div>
    </div>
    """
  end

  defp tab_content(assigns) do
    ~H"""
    <div class="alert alert-warning rounded">
      <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
      <span>Unknown tab</span>
    </div>
    """
  end

  # Event handlers
  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("move_trip", %{"id" => id, "direction" => direction}, socket) do
    trip = Tours.get_trip!(id)

    new_position =
      case direction do
        "up" -> trip.position - 1
        "down" -> trip.position + 1
      end

    Tours.move_trip(trip, new_position)
    trips = Tours.list_trips(socket.assigns.tour)
    {:noreply, assign(socket, :trips, trips)}
  end

  @impl true
  def handle_event("delete_trip", %{"id" => id}, socket) do
    trip = Tours.get_trip!(id)
    {:ok, _} = Tours.delete_trip(trip)
    trips = Tours.list_trips(socket.assigns.tour)
    {:noreply, assign(socket, :trips, trips)}
  end

  @impl true
  def handle_event("map_loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map_clicked", %{"lng" => lng, "lat" => lat}, socket) do
    IO.inspect({lng, lat}, label: "Map clicked at")
    {:noreply, socket}
  end

  @impl true
  def handle_info({GrandTourWeb.TripLive.FormComponent, {:saved, _trip}}, socket) do
    trips = Tours.list_trips(socket.assigns.tour)
    {:noreply, assign(socket, :trips, trips)}
  end

  # Helper functions
  defp status_summary(trips) do
    cond do
      trips == [] -> "No trips"
      Enum.all?(trips, &(&1.status == "completed")) -> "Completed"
      Enum.any?(trips, &(&1.status == "active")) -> "In Progress"
      true -> "Planning"
    end
  end

  defp status_badge_class(status) do
    case status do
      "active" -> "badge-success"
      "completed" -> "badge-info"
      _ -> "badge-ghost"
    end
  end

  defp format_date_range(start_date, nil), do: Calendar.strftime(start_date, "%b %d, %Y")

  defp format_date_range(start_date, end_date) do
    if start_date.year == end_date.year do
      "#{Calendar.strftime(start_date, "%b %d")} - #{Calendar.strftime(end_date, "%b %d, %Y")}"
    else
      "#{Calendar.strftime(start_date, "%b %d, %Y")} - #{Calendar.strftime(end_date, "%b %d, %Y")}"
    end
  end
end
