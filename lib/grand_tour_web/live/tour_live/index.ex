defmodule GrandTourWeb.TourLive.Index do
  use GrandTourWeb, :live_view

  alias GrandTour.Tours
  alias GrandTour.Tours.Tour

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    tours = Tours.list_tours(scope)

    {:ok,
     socket
     |> assign(:page_title, "Tours")
     |> assign(:has_tours, tours != [])
     |> stream(:tours, tours)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    scope = socket.assigns.current_scope

    socket
    |> assign(:page_title, "Edit Tour")
    |> assign(:tour, Tours.get_tour!(scope, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tour")
    |> assign(:tour, %Tour{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tours")
    |> assign(:tour, nil)
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:saved, tour}}, socket) do
    {:noreply,
     socket
     |> assign(:has_tours, true)
     |> stream_insert(:tours, tour, at: 0)}
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
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px-4 py-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <h1 class="text-3xl font-bold">Tours</h1>
            <p class="text-base-content/70 mt-1">Manage your trip planning tours</p>
          </div>
          <.link patch={~p"/tours/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Tour
          </.link>
        </div>

        <div id="tours" phx-update="stream" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div
            :for={{id, tour} <- @streams.tours}
            id={id}
            class="card bg-base-200 shadow-md hover:shadow-lg transition-shadow"
          >
            <div class="card-body">
              <h2 class="card-title">
                {tour.name}
                <span :if={tour.is_public} class="badge badge-success badge-sm">Public</span>
              </h2>
              <p :if={tour.subtitle} class="text-base-content/70">{tour.subtitle}</p>
              <p :if={!tour.subtitle} class="text-base-content/50 italic">No description</p>
              <div class="card-actions justify-end mt-4">
                <.link navigate={~p"/tours/#{tour}"} class="btn btn-sm btn-ghost">
                  <.icon name="hero-eye" class="w-4 h-4" /> View
                </.link>
                <.link patch={~p"/tours/#{tour}/edit"} class="btn btn-sm btn-ghost">
                  <.icon name="hero-pencil" class="w-4 h-4" /> Edit
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={tour.id}
                  data-confirm="Are you sure you want to delete this tour?"
                  class="btn btn-sm btn-ghost text-error"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <div :if={!@has_tours} class="text-center py-12">
          <.icon name="hero-map" class="w-16 h-16 mx-auto text-base-content/30" />
          <h3 class="mt-4 text-lg font-medium">No tours yet</h3>
          <p class="mt-2 text-base-content/70">Get started by creating your first tour.</p>
          <.link patch={~p"/tours/new"} class="btn btn-primary mt-4">
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> Create Tour
          </.link>
        </div>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="tour-modal"
          show
          on_cancel={JS.patch(~p"/tours")}
        >
          <.live_component
            module={GrandTourWeb.TourLive.FormComponent}
            id={@tour.id || :new}
            title={@page_title}
            action={@live_action}
            tour={@tour}
            scope={@current_scope}
            patch={~p"/tours"}
          />
        </.modal>
      </div>
    </Layouts.app>
    """
  end
end
