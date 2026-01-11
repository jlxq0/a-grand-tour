defmodule GrandTourWeb.TourLive.Show do
  use GrandTourWeb, :live_view

  alias GrandTour.Tours

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    tour = Tours.get_tour!(id)

    {:noreply,
     socket
     |> assign(:page_title, tour.name)
     |> assign(:tour, tour)}
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

            <div class="alert alert-info mt-6">
              <.icon name="hero-information-circle" class="w-5 h-5" />
              <span>Trips and routes will be added in Phase 2.2</span>
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
            patch={~p"/tours/#{@tour}"}
          />
        </.modal>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:saved, tour}}, socket) do
    {:noreply,
     socket
     |> assign(:tour, tour)
     |> assign(:page_title, tour.name)}
  end
end
