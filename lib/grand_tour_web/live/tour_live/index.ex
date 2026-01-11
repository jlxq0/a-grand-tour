defmodule GrandTourWeb.TourLive.Index do
  use GrandTourWeb, :live_view

  alias GrandTour.Tours
  alias GrandTour.Tours.Tour

  @impl true
  def mount(params, _session, socket) do
    scope = socket.assigns.current_scope
    user = scope.user
    tours = Tours.list_tours(scope)

    # Handle redirect from /tours to /:username/tours
    socket =
      if is_nil(params["username"]) do
        push_navigate(socket, to: ~p"/#{user.username}/tours")
      else
        socket
      end

    {:ok,
     socket
     |> assign(:page_title, "Overview")
     |> assign(:user, user)
     |> assign(:has_tours, tours != [])
     |> stream(:tours, tours)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tour")
    |> assign(:tour, %Tour{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Overview")
    |> assign(:tour, nil)
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:created, tour}}, socket) do
    # Navigate to the newly created tour
    {:noreply,
     socket
     |> assign(:has_tours, true)
     |> stream_insert(:tours, tour, at: 0)
     |> put_flash(:info, "Tour created successfully")
     |> push_navigate(to: ~p"/#{socket.assigns.user.username}/#{tour.slug}")}
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:updated, tour}}, socket) do
    {:noreply,
     socket
     |> stream_insert(:tours, tour)
     |> put_flash(:info, "Tour updated successfully")
     |> push_navigate(to: ~p"/#{socket.assigns.user.username}/#{tour.slug}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    tour = Tours.get_tour!(scope, id)
    {:ok, _} = Tours.delete_tour(tour)

    {:noreply, stream_delete(socket, :tours, tour)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} tour_title="Overview">
      <div class="container mx-auto px-4 py-8">
        <div id="tours" phx-update="stream" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div
            :for={{id, tour} <- @streams.tours}
            id={id}
            class="group relative aspect-[16/10] rounded overflow-hidden cursor-pointer"
            phx-click={JS.navigate(~p"/#{@user.username}/#{tour.slug}")}
          >
            <img
              src={tour.cover_image || default_cover_image(tour)}
              alt={tour.name}
              class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/85 via-black/35 to-black/10" />
            <div class="absolute inset-0 p-4 flex flex-col justify-between">
              <div class="flex justify-end">
                <span
                  :if={tour.is_public}
                  class="text-xs px-2 py-0.5 bg-white/20 backdrop-blur-sm text-white rounded"
                >
                  Public
                </span>
              </div>
              <div>
                <h2 class="text-xl font-semibold text-white">
                  {tour.name}
                </h2>
                <p :if={tour.subtitle} class="text-sm text-white/80 mt-1 line-clamp-1">
                  {tour.subtitle}
                </p>
                <div class="flex items-center gap-3 mt-2 text-xs text-white/90">
                  <span class="flex items-center gap-1">
                    <.icon name="hero-map" class="w-3.5 h-3.5" />
                    {trip_count(tour)} trips
                  </span>
                  <span class="flex items-center gap-1">
                    <.icon name="hero-calendar" class="w-3.5 h-3.5" />
                    {format_date(tour.inserted_at)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <%!-- New Tour Card --%>
          <.link
            id="new-tour-card"
            patch={~p"/#{@user.username}/tours/new"}
            class="group relative aspect-[16/10] rounded overflow-hidden bg-base-200 hover:bg-base-300 transition-colors"
          >
            <div class="absolute inset-0 flex flex-col items-center justify-center">
              <.icon
                name="hero-plus"
                class="w-8 h-8 text-base-content/30 group-hover:text-base-content/50 transition-colors"
              />
              <span class="text-sm text-base-content/40 group-hover:text-base-content/60 mt-2 transition-colors">
                New Tour
              </span>
            </div>
          </.link>
        </div>

        <div :if={!@has_tours} class="text-center py-16">
          <div class="w-16 h-16 rounded-lg bg-base-200 flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-globe-americas" class="w-8 h-8 text-primary/60" />
          </div>
          <h3 class="text-xl font-semibold mb-1">Start Your Journey</h3>
          <p class="text-base-content/60 text-sm max-w-sm mx-auto mb-6">
            Create your first tour to begin planning an overland adventure.
          </p>
          <.link patch={~p"/#{@user.username}/tours/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="w-4 h-4" /> Create Tour
          </.link>
        </div>

        <.modal
          :if={@live_action in [:new]}
          id="tour-modal"
          show
          on_cancel={JS.patch(~p"/#{@user.username}/tours")}
        >
          <.live_component
            module={GrandTourWeb.TourLive.FormComponent}
            id={@tour.id || :new}
            title={@page_title}
            action={@live_action}
            tour={@tour}
            scope={@current_scope}
            user={@user}
            patch={~p"/#{@user.username}/tours"}
          />
        </.modal>
      </div>
    </Layouts.app>
    """
  end

  defp default_cover_image(tour) do
    # Use a hash of the tour ID to pick a consistent default image
    index = :erlang.phash2(tour.id, 4) + 1
    "/images/tours/tour-#{index}.jpg"
  end

  defp trip_count(tour) do
    case tour.trips do
      %Ecto.Association.NotLoaded{} -> 0
      trips -> length(trips)
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %Y")
  end
end
