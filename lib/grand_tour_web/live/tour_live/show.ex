defmodule GrandTourWeb.TourLive.Show do
  use GrandTourWeb, :live_view

  alias GrandTour.Tours
  alias GrandTour.Tours.Trip

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    scope = socket.assigns.current_scope
    tour = Tours.get_tour!(scope, id)
    trips = Tours.list_trips(tour)

    socket =
      socket
      |> assign(:page_title, tour.name)
      |> assign(:tour, tour)
      |> assign(:has_trips, trips != [])
      |> stream(:trips, trips)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
  end

  defp apply_action(socket, :new_trip, _params) do
    socket
    |> assign(:trip, %Trip{tour_id: socket.assigns.tour.id})
  end

  defp apply_action(socket, :edit_trip, %{"trip_id" => trip_id}) do
    socket
    |> assign(:trip, Tours.get_trip!(trip_id))
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:trip, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px-4 py-8">
        <div class="mb-6">
          <.link navigate={~p"/tours"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> Back to Tours
          </.link>
        </div>

        <div class="card bg-base-200 shadow-lg">
          <div class="card-body">
            <div class="flex justify-between items-start">
              <div>
                <h1 class="card-title text-3xl">
                  {@tour.name}
                  <span :if={@tour.is_public} class="badge badge-success">Public</span>
                  <span :if={!@tour.is_public} class="badge badge-ghost">Private</span>
                </h1>
                <p :if={@tour.subtitle} class="text-base-content/70 mt-2 text-lg">
                  {@tour.subtitle}
                </p>
              </div>
              <div class="flex gap-2">
                <.link patch={~p"/tours/#{@tour}/show/edit"} class="btn btn-sm btn-ghost">
                  <.icon name="hero-pencil" class="w-4 h-4" /> Edit
                </.link>
              </div>
            </div>

            <div class="divider"></div>

            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-base-content/50">Created</span>
                <p class="font-medium">{Calendar.strftime(@tour.inserted_at, "%B %d, %Y")}</p>
              </div>
              <div>
                <span class="text-base-content/50">Last Updated</span>
                <p class="font-medium">{Calendar.strftime(@tour.updated_at, "%B %d, %Y")}</p>
              </div>
            </div>

            <div class="divider"></div>

            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold">Trips</h2>
              <.link patch={~p"/tours/#{@tour}/trips/new"} class="btn btn-primary btn-sm">
                <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Trip
              </.link>
            </div>

            <div :if={!@has_trips} class="text-center py-8 bg-base-100 rounded-lg">
              <.icon name="hero-map-pin" class="w-12 h-12 mx-auto text-base-content/30" />
              <p class="mt-2 text-base-content/70">
                No trips yet. Add your first trip to get started.
              </p>
            </div>

            <div id="trips" phx-update="stream" class="space-y-3">
              <div
                :for={{id, trip} <- @streams.trips}
                id={id}
                class="card bg-base-100 shadow-sm hover:shadow-md transition-shadow"
              >
                <div class="card-body p-4">
                  <div class="flex justify-between items-start">
                    <div class="flex items-center gap-3">
                      <div class="badge badge-outline badge-lg font-mono">{trip.position}</div>
                      <div>
                        <h3 class="font-semibold">{trip.name}</h3>
                        <p :if={trip.subtitle} class="text-sm text-base-content/70">
                          {trip.subtitle}
                        </p>
                        <div class="flex gap-2 mt-1">
                          <span class={"badge badge-sm #{status_badge_class(trip.status)}"}>
                            {trip.status}
                          </span>
                          <span :if={trip.start_date} class="text-xs text-base-content/50">
                            {format_date_range(trip.start_date, trip.end_date)}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="flex gap-1">
                      <button
                        :if={trip.position > 1}
                        phx-click="move_trip"
                        phx-value-id={trip.id}
                        phx-value-direction="up"
                        class="btn btn-ghost btn-xs"
                        title="Move up"
                      >
                        <.icon name="hero-chevron-up" class="w-4 h-4" />
                      </button>
                      <button
                        phx-click="move_trip"
                        phx-value-id={trip.id}
                        phx-value-direction="down"
                        class="btn btn-ghost btn-xs"
                        title="Move down"
                      >
                        <.icon name="hero-chevron-down" class="w-4 h-4" />
                      </button>
                      <.link
                        patch={~p"/tours/#{@tour}/trips/#{trip}/edit"}
                        class="btn btn-ghost btn-xs"
                      >
                        <.icon name="hero-pencil" class="w-4 h-4" />
                      </.link>
                      <button
                        phx-click="delete_trip"
                        phx-value-id={trip.id}
                        data-confirm="Are you sure you want to delete this trip?"
                        class="btn btn-ghost btn-xs text-error"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <.modal
          :if={@live_action == :edit}
          id="tour-modal"
          show
          on_cancel={JS.patch(~p"/tours/#{@tour}")}
        >
          <.live_component
            module={GrandTourWeb.TourLive.FormComponent}
            id={@tour.id}
            title="Edit Tour"
            action={:edit}
            tour={@tour}
            scope={@current_scope}
            patch={~p"/tours/#{@tour}"}
          />
        </.modal>

        <.modal
          :if={@live_action in [:new_trip, :edit_trip]}
          id="trip-modal"
          show
          on_cancel={JS.patch(~p"/tours/#{@tour}")}
        >
          <.live_component
            module={GrandTourWeb.TripLive.FormComponent}
            id={@trip.id || :new}
            title={if @live_action == :new_trip, do: "New Trip", else: "Edit Trip"}
            action={@live_action}
            trip={@trip}
            tour={@tour}
            patch={~p"/tours/#{@tour}"}
          />
        </.modal>
      </div>
    </Layouts.app>
    """
  end

  defp status_badge_class("planning"), do: "badge-info"
  defp status_badge_class("active"), do: "badge-success"
  defp status_badge_class("completed"), do: "badge-neutral"
  defp status_badge_class(_), do: "badge-ghost"

  defp format_date_range(nil, _), do: nil
  defp format_date_range(start_date, nil), do: Calendar.strftime(start_date, "%b %d, %Y")

  defp format_date_range(start_date, end_date) do
    "#{Calendar.strftime(start_date, "%b %d")} - #{Calendar.strftime(end_date, "%b %d, %Y")}"
  end

  @impl true
  def handle_event("delete_trip", %{"id" => id}, socket) do
    trip = Tours.get_trip!(id)
    {:ok, _} = Tours.delete_trip(trip)

    trips = Tours.list_trips(socket.assigns.tour)

    {:noreply,
     socket
     |> assign(:has_trips, trips != [])
     |> stream(:trips, trips, reset: true)}
  end

  @impl true
  def handle_event("move_trip", %{"id" => id, "direction" => direction}, socket) do
    trip = Tours.get_trip!(id)
    trips = Tours.list_trips(socket.assigns.tour)
    max_position = length(trips)

    new_position =
      case direction do
        "up" -> max(1, trip.position - 1)
        "down" -> min(max_position, trip.position + 1)
      end

    if new_position != trip.position do
      {:ok, _} = Tours.move_trip(trip, new_position)
      trips = Tours.list_trips(socket.assigns.tour)
      {:noreply, stream(socket, :trips, trips, reset: true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:saved, tour}}, socket) do
    {:noreply,
     socket
     |> assign(:tour, tour)
     |> assign(:page_title, tour.name)}
  end

  @impl true
  def handle_info({GrandTourWeb.TripLive.FormComponent, {:saved, trip}}, socket) do
    {:noreply,
     socket
     |> assign(:has_trips, true)
     |> stream_insert(:trips, trip)}
  end
end
