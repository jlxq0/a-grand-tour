defmodule GrandTourWeb.AppLive do
  use GrandTourWeb, :live_view

  alias GrandTour.Accounts
  alias GrandTour.Tours
  alias GrandTour.Datasets

  @impl true
  def mount(_params, _session, socket) do
    mapbox_token = Application.get_env(:grand_tour, :mapbox)[:access_token]

    {:ok,
     socket
     |> assign(:mapbox_token, mapbox_token)
     |> assign(:user, nil)
     |> assign(:tour, nil)
     |> assign(:trips, [])
     |> assign(:trip, nil)
     |> assign(:datasets, [])
     |> assign(:dataset, nil)
     |> assign(:dataset_items, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Load user and tour from URL params
  defp load_user_and_tour(socket, %{"username" => username, "tour_slug" => tour_slug}) do
    user = Accounts.get_user_by_username!(username)
    tour = Tours.get_tour_by_slug!(user, tour_slug)
    trips = Tours.list_trips(tour)
    datasets = Datasets.list_all_datasets(tour.id)

    socket
    |> assign(:user, user)
    |> assign(:tour, tour)
    |> assign(:trips, trips)
    |> assign(:datasets, datasets)
  end

  defp apply_action(socket, :overview, params) do
    socket = load_user_and_tour(socket, params)

    socket
    |> assign(:page_title, socket.assigns.tour.name)
    |> assign(:trip, nil)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :trip, %{"trip_slug" => trip_slug} = params) do
    socket = load_user_and_tour(socket, params)
    trip = Tours.get_trip_by_slug!(socket.assigns.tour, trip_slug)

    socket
    |> assign(:page_title, "#{trip.name} - #{socket.assigns.tour.name}")
    |> assign(:trip, trip)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :timeline, params) do
    socket = load_user_and_tour(socket, params)

    socket
    |> assign(:page_title, "Timeline - #{socket.assigns.tour.name}")
    |> assign(:trip, nil)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :dataset, %{"dataset_id" => dataset_id} = params) do
    socket = load_user_and_tour(socket, params)
    dataset = Datasets.get_dataset!(dataset_id)
    items = Datasets.list_dataset_items(dataset_id)

    socket
    |> assign(:page_title, "#{dataset.name} - #{socket.assigns.tour.name}")
    |> assign(:trip, nil)
    |> assign(:dataset, dataset)
    |> assign(:dataset_items, items)
  end

  defp apply_action(socket, :documents, params) do
    socket = load_user_and_tour(socket, params)

    socket
    |> assign(:page_title, "Documents - #{socket.assigns.tour.name}")
    |> assign(:trip, nil)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :new_trip, params) do
    socket = load_user_and_tour(socket, params)

    socket
    |> assign(:page_title, "New Trip")
    |> assign(:trip, %Tours.Trip{})
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :edit_trip, %{"trip_slug" => trip_slug} = params) do
    socket = load_user_and_tour(socket, params)
    trip = Tours.get_trip_by_slug!(socket.assigns.tour, trip_slug)

    socket
    |> assign(:page_title, "Edit Trip")
    |> assign(:trip, trip)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :edit_tour, params) do
    socket
    |> load_user_and_tour(params)
    |> assign(:page_title, "Edit Tour")
    |> assign(:trip, nil)
    |> assign(:dataset, nil)
    |> assign(:dataset_items, [])
  end

  defp apply_action(socket, :new_dataset, params) do
    socket
    |> load_user_and_tour(params)
    |> assign(:page_title, "New Dataset")
    |> assign(:trip, nil)
    |> assign(:dataset, %Datasets.Dataset{})
    |> assign(:dataset_items, [])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      tour_title={@tour && @tour.name}
      tour_id={@tour && @tour.id}
    >
      <div id="app-container" class="flex flex-col h-[calc(100vh-4rem)]">
        <%!-- Navigation Tabs --%>
        <nav class="flex items-center border-b border-base-300 px-4 flex-shrink-0 h-12">
          <%!-- Left: Back to Tours --%>
          <.link navigate={~p"/#{@user.username}/tours"} class="tab">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Tours
          </.link>

          <%!-- Center: Tabs --%>
          <div class="tabs tabs-border flex-1">
            <%!-- Overview --%>
            <.link
              navigate={~p"/#{@user.username}/#{@tour.slug}"}
              class={nav_link_class(@live_action == :overview)}
            >
              Overview
            </.link>

            <%!-- Trips Dropdown --%>
            <div class="dropdown">
              <label
                tabindex="0"
                class={[
                  "tab cursor-pointer gap-1",
                  @live_action in [:trip, :new_trip, :edit_trip] && "tab-active"
                ]}
              >
                Trips <.icon name="hero-chevron-down" class="w-3 h-3" />
              </label>
              <ul
                tabindex="0"
                class="dropdown-content menu bg-base-200 rounded w-56 shadow-lg z-50 p-2"
              >
                <li :for={trip <- @trips}>
                  <.link navigate={~p"/#{@user.username}/#{@tour.slug}/trips/#{trip.slug}"}>
                    <span class="badge badge-ghost badge-sm">{trip.position}</span>
                    {trip.name}
                  </.link>
                </li>
                <li :if={@trips != []} class="menu-title pt-2">
                  <span></span>
                </li>
                <li>
                  <.link
                    navigate={~p"/#{@user.username}/#{@tour.slug}/trips/new"}
                    class="text-primary"
                  >
                    <.icon name="hero-plus" class="w-4 h-4" /> Add Trip
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Timeline --%>
            <.link
              navigate={~p"/#{@user.username}/#{@tour.slug}/timeline"}
              class={nav_link_class(@live_action == :timeline)}
            >
              Timeline
            </.link>

            <%!-- Datasets Dropdown --%>
            <div class="dropdown">
              <label
                tabindex="0"
                class={[
                  "tab cursor-pointer gap-1",
                  @live_action in [:dataset, :new_dataset] && "tab-active"
                ]}
              >
                Datasets <.icon name="hero-chevron-down" class="w-3 h-3" />
              </label>
              <ul
                tabindex="0"
                class="dropdown-content menu bg-base-200 rounded w-64 shadow-lg z-50 p-2 max-h-96 overflow-y-auto"
              >
                <li :if={Enum.any?(@datasets, & &1.is_system)} class="menu-title">
                  <span>System</span>
                </li>
                <li :for={dataset <- Enum.filter(@datasets, & &1.is_system)}>
                  <.link navigate={~p"/#{@user.username}/#{@tour.slug}/datasets/#{dataset.id}"}>
                    <.icon name={geometry_icon(dataset.geometry_type)} class="w-4 h-4" />
                    {dataset.name}
                  </.link>
                </li>
                <li :if={Enum.any?(@datasets, &(!&1.is_system))} class="menu-title pt-2">
                  <span>My Datasets</span>
                </li>
                <li :for={dataset <- Enum.reject(@datasets, & &1.is_system)}>
                  <.link navigate={~p"/#{@user.username}/#{@tour.slug}/datasets/#{dataset.id}"}>
                    <.icon name={geometry_icon(dataset.geometry_type)} class="w-4 h-4" />
                    {dataset.name}
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Documents --%>
            <.link
              navigate={~p"/#{@user.username}/#{@tour.slug}/documents"}
              class={nav_link_class(@live_action == :documents)}
            >
              Documents
            </.link>
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
              <.page_content
                live_action={@live_action}
                user={@user}
                tour={@tour}
                trips={@trips}
                trip={@trip}
                datasets={@datasets}
                dataset={@dataset}
                dataset_items={@dataset_items}
              />
            </div>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new_trip, :edit_trip]}
        id="trip-modal"
        show
        on_cancel={JS.patch(~p"/#{@user.username}/#{@tour.slug}")}
      >
        <.live_component
          module={GrandTourWeb.TripLive.FormComponent}
          id={@trip.id || :new}
          title={@page_title}
          action={@live_action}
          trip={@trip}
          tour={@tour}
          user={@user}
          patch={~p"/#{@user.username}/#{@tour.slug}"}
        />
      </.modal>

      <.modal
        :if={@live_action == :edit_tour}
        id="tour-modal"
        show
        on_cancel={JS.patch(~p"/#{@user.username}/#{@tour.slug}")}
      >
        <.live_component
          module={GrandTourWeb.TourLive.FormComponent}
          id={@tour.id}
          title={@page_title}
          action={:edit}
          tour={@tour}
          scope={@current_scope}
          user={@user}
          patch={~p"/#{@user.username}/#{@tour.slug}"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  # Navigation link helper - uses DaisyUI tab styling with underline
  defp nav_link_class(active) do
    if active, do: "tab tab-active", else: "tab"
  end

  # Page content based on live_action
  attr :live_action, :atom, required: true
  attr :user, :map, required: true
  attr :tour, :map, required: true
  attr :trips, :list, required: true
  attr :trip, :map
  attr :datasets, :list, required: true
  attr :dataset, :map
  attr :dataset_items, :list, default: []

  defp page_content(%{live_action: :overview} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <div class="flex items-start justify-between">
        <div class="group/title flex items-center gap-2">
          <h1 class="mb-2 text-3xl">{@tour.name}</h1>
          <.link
            navigate={~p"/#{@user.username}/#{@tour.slug}/edit"}
            class="opacity-0 group-hover/title:opacity-100 transition-opacity mb-2"
            title="Edit tour"
          >
            <.icon name="hero-pencil" class="w-5 h-5 text-base-content/50 hover:text-primary" />
          </.link>
        </div>
        <span class={[
          "badge",
          @tour.is_public && "badge-success",
          !@tour.is_public && "badge-ghost"
        ]}>
          {if @tour.is_public, do: "Public", else: "Private"}
        </span>
      </div>
      <p :if={@tour.subtitle} class="lead text-lg text-base-content/70 mt-0">
        {@tour.subtitle}
      </p>

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

  defp page_content(%{live_action: action} = assigns)
       when action in [:trip, :new_trip, :edit_trip] do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <div>
          <h1 class="text-2xl font-bold">{(@trip && @trip.name) || "Trip"}</h1>
          <p :if={@trip && @trip.subtitle} class="text-base-content/60">{@trip.subtitle}</p>
        </div>
        <div :if={@trip && @trip.id} class="flex gap-2">
          <.link
            navigate={~p"/#{@user.username}/#{@tour.slug}/trips/#{@trip.slug}/edit"}
            class="btn btn-ghost btn-sm"
          >
            <.icon name="hero-pencil" class="w-4 h-4" /> Edit
          </.link>
          <button
            :if={length(@trips) > 1}
            phx-click="delete_trip"
            phx-value-id={@trip.id}
            data-confirm="Delete this trip?"
            class="btn btn-ghost btn-sm text-error"
          >
            <.icon name="hero-trash" class="w-4 h-4" /> Delete
          </button>
        </div>
      </div>

      <div :if={@trip && @trip.id} class="space-y-4">
        <div class="flex gap-2 flex-wrap">
          <span class={["badge", status_badge_class(@trip.status)]}>
            {@trip.status || "planning"}
          </span>
          <span :if={@trip.start_date} class="badge badge-ghost">
            {format_date_range(@trip.start_date, @trip.end_date)}
          </span>
        </div>

        <div class="alert alert-info rounded">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>Trip route planning coming soon</span>
        </div>
      </div>
    </div>
    """
  end

  defp page_content(%{live_action: :timeline} = assigns) do
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

  defp page_content(%{live_action: action} = assigns) when action in [:dataset, :new_dataset] do
    ~H"""
    <div>
      <div :if={@dataset && @dataset.id}>
        <div class="flex items-center justify-between mb-4">
          <div>
            <h1 class="text-2xl font-bold">{@dataset.name}</h1>
            <p :if={@dataset.description} class="text-base-content/60">{@dataset.description}</p>
          </div>
          <div class="flex gap-2">
            <span class="badge badge-outline">{@dataset.geometry_type}</span>
            <span :if={@dataset.is_system} class="badge badge-info badge-outline">System</span>
          </div>
        </div>

        <div class="mb-4">
          <span class="badge badge-ghost">{length(@dataset_items)} items</span>
        </div>

        <div :if={@dataset_items == []} class="text-center py-12 text-base-content/50">
          <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-4 opacity-50" />
          <p>No items in this dataset.</p>
        </div>

        <div :if={@dataset_items != []} class="space-y-2">
          <div
            :for={item <- Enum.take(@dataset_items, 50)}
            class="p-3 bg-base-200 rounded-lg hover:bg-base-300 cursor-pointer transition-colors"
          >
            <div class="flex items-start gap-3">
              <div :if={item.images != []} class="flex-shrink-0">
                <img
                  src={"/images/" <> List.first(item.images)}
                  alt={item.name}
                  class="w-12 h-12 object-cover rounded"
                />
              </div>
              <div class="flex-1 min-w-0">
                <div class="font-medium truncate">{item.name}</div>
                <div :if={item.description} class="text-sm text-base-content/60 line-clamp-2">
                  {item.description}
                </div>
                <div :if={item.rating} class="mt-1">
                  <span class="text-warning text-sm">
                    {String.duplicate("★", item.rating)}{String.duplicate("☆", 5 - item.rating)}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div :if={length(@dataset_items) > 50} class="text-center text-sm text-base-content/50 py-2">
            Showing 50 of {length(@dataset_items)} items
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp page_content(%{live_action: :documents} = assigns) do
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

  defp page_content(assigns) do
    ~H"""
    <div class="alert alert-warning rounded">
      <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
      <span>Unknown page</span>
    </div>
    """
  end

  # Event handlers
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

    case Tours.delete_trip(trip) do
      {:ok, _} ->
        trips = Tours.list_trips(socket.assigns.tour)
        first_trip = List.first(trips)

        socket =
          socket
          |> assign(:trips, trips)
          |> put_flash(:info, "Trip deleted")

        # Navigate to first remaining trip
        if first_trip do
          {:noreply,
           push_navigate(socket,
             to:
               ~p"/#{socket.assigns.user.username}/#{socket.assigns.tour.slug}/trips/#{first_trip.slug}"
           )}
        else
          {:noreply,
           push_navigate(socket,
             to: ~p"/#{socket.assigns.user.username}/#{socket.assigns.tour.slug}"
           )}
        end

      {:error, :last_trip} ->
        {:noreply, put_flash(socket, :error, "Cannot delete the last trip")}
    end
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
  def handle_info({GrandTourWeb.TripLive.FormComponent, {:created, trip}}, socket) do
    trips = Tours.list_trips(socket.assigns.tour)

    {:noreply,
     socket
     |> assign(:trips, trips)
     |> put_flash(:info, "Trip created successfully")
     |> push_navigate(
       to: ~p"/#{socket.assigns.user.username}/#{socket.assigns.tour.slug}/trips/#{trip.slug}"
     )}
  end

  @impl true
  def handle_info({GrandTourWeb.TripLive.FormComponent, {:updated, trip}}, socket) do
    trips = Tours.list_trips(socket.assigns.tour)

    {:noreply,
     socket
     |> assign(:trips, trips)
     |> put_flash(:info, "Trip updated successfully")
     |> push_navigate(
       to: ~p"/#{socket.assigns.user.username}/#{socket.assigns.tour.slug}/trips/#{trip.slug}"
     )}
  end

  @impl true
  def handle_info({GrandTourWeb.TourLive.FormComponent, {:updated, tour}}, socket) do
    {:noreply,
     socket
     |> assign(:tour, tour)
     |> put_flash(:info, "Tour updated successfully")
     |> push_navigate(to: ~p"/#{socket.assigns.user.username}/#{tour.slug}")}
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

  defp geometry_icon("point"), do: "hero-map-pin"
  defp geometry_icon("line"), do: "hero-arrow-trending-up"
  defp geometry_icon("polygon"), do: "hero-square-2-stack"
  defp geometry_icon(_), do: "hero-document"
end
