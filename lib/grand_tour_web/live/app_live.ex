defmodule GrandTourWeb.AppLive do
  use GrandTourWeb, :live_view

  alias GrandTour.Accounts
  alias GrandTour.Tours
  alias GrandTour.Datasets

  import GrandTourWeb.DatasetViews
  import GrandTourWeb.DatasetFilter
  import GrandTourWeb.SharedComponents, only: [section_header: 1]

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
     |> assign(:dataset_items, [])
     # Dataset view state
     |> assign(:view_type, "list")
     |> assign(:view_prefs, %{})
     |> assign(:quick_filter, "")
     |> assign(:default_filter, "")
     |> assign(:sort_field, "name")
     |> assign(:sort_direction, "asc")
     |> assign(:card_style, "image_overlay")
     |> assign(:visible_fields, ["name", "description", "rating"])
     |> assign(:visible_fields_list, ["name", "description", "rating"])
     |> assign(:visible_fields_table, ["name", "rating", "country_code"])
     |> assign(:visible_fields_card, ["name", "description", "rating", "images"])
     |> assign(:dataset_page, 0)
     |> assign(:dataset_has_more, false)
     |> assign(:dataset_total, 0)
     |> assign(:dataset_loading, false)
     |> assign(:show_settings_modal, false)
     |> assign(:settings_tab, "general")
     |> assign(:show_filter_builder, false)
     |> assign(:active_filters, [])
     |> assign(:available_fields, [])}
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

    # Get user's preferences for this dataset (or defaults)
    current_user_id =
      if socket.assigns[:scope], do: socket.assigns.scope.current_user_id, else: nil

    prefs = Datasets.get_user_preferences(current_user_id, dataset_id)
    view_type = Map.get(prefs, "view_type", "card")
    sort_field = Map.get(prefs, "sort_field", "name")
    sort_direction = Map.get(prefs, "sort_direction", "asc")
    card_style = Map.get(prefs, "card_style", "image_overlay")
    default_filter = Map.get(prefs, "default_filter") || ""

    # Per-view visible fields
    visible_fields_list =
      Map.get(prefs, "visible_fields_list", ["name", "description", "rating", "images"])

    visible_fields_table =
      Map.get(prefs, "visible_fields_table", ["name", "rating", "country_code", "images"])

    visible_fields_card =
      Map.get(prefs, "visible_fields_card", ["name", "description", "rating", "images"])

    # Get the visible fields for the current view type
    visible_fields =
      case view_type do
        "list" -> visible_fields_list
        "table" -> visible_fields_table
        "card" -> visible_fields_card
        _ -> visible_fields_list
      end

    # Get total count (with default filter if set)
    filter_to_apply = if default_filter != "", do: default_filter, else: nil
    total = Datasets.count_dataset_items(dataset_id, filter_to_apply)

    # Load initial page of items (with default filter if set)
    items =
      Datasets.list_dataset_items_paginated(dataset_id,
        limit: 50,
        offset: 0,
        sort_field: sort_field,
        sort_direction: sort_direction,
        filter: filter_to_apply
      )

    has_more = length(items) == 50 && total > 50

    socket
    |> assign(:page_title, "#{dataset.name} - #{socket.assigns.tour.name}")
    |> assign(:trip, nil)
    |> assign(:dataset, dataset)
    |> assign(:dataset_items, items)
    |> assign(:view_type, view_type)
    |> assign(:view_prefs, prefs)
    |> assign(:sort_field, sort_field)
    |> assign(:sort_direction, sort_direction)
    |> assign(:card_style, card_style)
    |> assign(:visible_fields, visible_fields)
    |> assign(:visible_fields_list, visible_fields_list)
    |> assign(:visible_fields_table, visible_fields_table)
    |> assign(:visible_fields_card, visible_fields_card)
    |> assign(:default_filter, default_filter)
    |> assign(:quick_filter, default_filter)
    |> assign(:dataset_page, 0)
    |> assign(:dataset_has_more, has_more)
    |> assign(:dataset_total, total)
    |> assign(:dataset_loading, false)
    |> assign(:settings_tab, "general")
    |> assign(:show_filter_builder, false)
    |> assign(:active_filters, [])
    |> assign(:available_fields, get_dataset_fields(dataset))
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
                view_type={@view_type}
                view_prefs={@view_prefs}
                quick_filter={@quick_filter}
                default_filter={@default_filter}
                sort_field={@sort_field}
                sort_direction={@sort_direction}
                card_style={@card_style}
                visible_fields={@visible_fields}
                visible_fields_list={@visible_fields_list}
                visible_fields_table={@visible_fields_table}
                visible_fields_card={@visible_fields_card}
                dataset_page={@dataset_page}
                dataset_has_more={@dataset_has_more}
                dataset_total={@dataset_total}
                dataset_loading={@dataset_loading}
                show_settings_modal={@show_settings_modal}
                settings_tab={@settings_tab}
                show_filter_builder={@show_filter_builder}
                active_filters={@active_filters}
                available_fields={@available_fields}
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
  # Dataset view state
  attr :view_type, :string, default: "list"
  attr :view_prefs, :map, default: %{}
  attr :quick_filter, :string, default: ""
  attr :default_filter, :string, default: ""
  attr :sort_field, :string, default: "name"
  attr :sort_direction, :string, default: "asc"
  attr :card_style, :string, default: "image_overlay"
  attr :visible_fields, :list, default: ["name", "description", "rating"]
  attr :visible_fields_list, :list, default: ["name", "description", "rating"]
  attr :visible_fields_table, :list, default: ["name", "rating", "country_code"]
  attr :visible_fields_card, :list, default: ["name", "description", "rating", "images"]
  attr :dataset_page, :integer, default: 0
  attr :dataset_has_more, :boolean, default: false
  attr :dataset_total, :integer, default: 0
  attr :dataset_loading, :boolean, default: false
  attr :show_settings_modal, :boolean, default: false
  attr :settings_tab, :string, default: "general"
  attr :show_filter_builder, :boolean, default: false
  attr :active_filters, :list, default: []
  attr :available_fields, :list, default: []

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
    # Determine label for new item based on dataset type
    new_label = new_item_label(assigns.dataset)

    assigns = assign(assigns, :new_label, new_label)

    ~H"""
    <div>
      <div :if={@dataset && @dataset.id}>
        <%!-- Header matching tour overview style --%>
        <.section_header
          title={@dataset.name}
          subtitle={@dataset.description}
          edit_event="open_settings"
        />

        <%!-- Filter bar --%>
        <.dataset_filter_bar
          view_type={@view_type}
          filter_value={@quick_filter}
          item_count={@dataset_total}
          available_fields={@available_fields}
          active_filters={@active_filters}
          show_filter_builder={@show_filter_builder}
          on_view_change="switch_view"
          on_filter_change="filter_items"
          on_toggle_filter_builder="toggle_filter_builder"
          on_add_filter="add_filter"
          on_remove_filter="remove_filter"
        />

        <%!-- Dataset items view (show even if empty to show + New card) --%>
        <%= case @view_type do %>
          <% "table" -> %>
            <%!-- Empty state for table --%>
            <div :if={@dataset_items == []} class="text-center py-12 text-base-content/50">
              <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>No items in this dataset.</p>
            </div>
            <.dataset_table_view
              :if={@dataset_items != []}
              items={@dataset_items}
              visible_fields={@visible_fields}
              sort_field={@sort_field}
              sort_direction={@sort_direction}
              on_sort="sort"
              on_click="select_item"
              media_url_fn={&media_url/1}
            />
          <% "card" -> %>
            <.dataset_card_view
              items={@dataset_items}
              visible_fields={@visible_fields}
              card_style={@card_style}
              on_click="select_item"
              on_new="new_item"
              new_label={@new_label}
              media_url_fn={&media_url/1}
            />
          <% _ -> %>
            <%!-- Empty state for list --%>
            <div :if={@dataset_items == []} class="text-center py-12 text-base-content/50">
              <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>No items in this dataset.</p>
            </div>
            <.dataset_list_view
              :if={@dataset_items != []}
              items={@dataset_items}
              visible_fields={@visible_fields}
              on_click="select_item"
              media_url_fn={&media_url/1}
            />
        <% end %>

        <%!-- Load more trigger --%>
        <.load_more_trigger
          :if={@dataset_items != []}
          has_more={@dataset_has_more}
          loading={@dataset_loading}
        />

        <%!-- Settings Modal --%>
        <.settings_modal
          :if={@show_settings_modal}
          dataset={@dataset}
          view_type={@view_type}
          visible_fields_list={@visible_fields_list}
          visible_fields_table={@visible_fields_table}
          visible_fields_card={@visible_fields_card}
          sort_field={@sort_field}
          sort_direction={@sort_direction}
          default_filter={@default_filter}
          settings_tab={@settings_tab}
        />
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

  # Dataset view events
  def handle_event("switch_view", %{"view" => view}, socket) do
    # Update visible_fields based on the selected view type
    visible_fields =
      case view do
        "list" -> socket.assigns.visible_fields_list
        "table" -> socket.assigns.visible_fields_table
        "card" -> socket.assigns.visible_fields_card
        _ -> socket.assigns.visible_fields
      end

    {:noreply,
     socket
     |> assign(:view_type, view)
     |> assign(:visible_fields, visible_fields)}
  end

  def handle_event("settings_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :settings_tab, tab)}
  end

  def handle_event("filter_items", %{"filter" => filter}, socket) do
    # Filter is applied client-side for instant feedback,
    # but we also update the assign for when loading more items
    {:noreply, assign(socket, :quick_filter, filter)}
  end

  def handle_event("toggle_filter_builder", _params, socket) do
    {:noreply, assign(socket, :show_filter_builder, !socket.assigns.show_filter_builder)}
  end

  def handle_event("add_filter", %{"field" => field, "op" => op, "value" => value}, socket) do
    new_filter = %{field: field, op: op, value: value}
    active_filters = socket.assigns.active_filters ++ [new_filter]

    # Apply filters to reload data
    socket = reload_with_filters(socket, active_filters)

    {:noreply,
     socket
     |> assign(:active_filters, active_filters)
     |> assign(:show_filter_builder, false)}
  end

  def handle_event("remove_filter", %{"index" => index}, socket) do
    index = String.to_integer(index)
    active_filters = List.delete_at(socket.assigns.active_filters, index)

    # Apply remaining filters to reload data
    socket = reload_with_filters(socket, active_filters)

    {:noreply, assign(socket, :active_filters, active_filters)}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    # Toggle direction if same field, otherwise default to asc
    new_direction =
      if socket.assigns.sort_field == field do
        if socket.assigns.sort_direction == "asc", do: "desc", else: "asc"
      else
        "asc"
      end

    # Reload items with new sort
    items =
      Datasets.list_dataset_items_paginated(socket.assigns.dataset.id,
        limit: 50,
        offset: 0,
        sort_field: field,
        sort_direction: new_direction,
        filter: socket.assigns.quick_filter
      )

    {:noreply,
     socket
     |> assign(:sort_field, field)
     |> assign(:sort_direction, new_direction)
     |> assign(:dataset_items, items)
     |> assign(:dataset_page, 0)
     |> assign(:dataset_has_more, length(items) == 50)}
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.dataset_loading || !socket.assigns.dataset_has_more do
      {:noreply, socket}
    else
      socket = assign(socket, :dataset_loading, true)
      page = socket.assigns.dataset_page + 1
      offset = page * 50

      # Enforce hard limit of 1000 items
      if offset >= 1000 do
        {:noreply, assign(socket, dataset_has_more: false, dataset_loading: false)}
      else
        new_items =
          Datasets.list_dataset_items_paginated(socket.assigns.dataset.id,
            limit: 50,
            offset: offset,
            sort_field: socket.assigns.sort_field,
            sort_direction: socket.assigns.sort_direction,
            filter: socket.assigns.quick_filter
          )

        has_more = length(new_items) == 50 && offset + 50 < 1000

        {:noreply,
         socket
         |> assign(:dataset_items, socket.assigns.dataset_items ++ new_items)
         |> assign(:dataset_page, page)
         |> assign(:dataset_has_more, has_more)
         |> assign(:dataset_loading, false)}
      end
    end
  end

  def handle_event("select_item", %{"id" => _id}, socket) do
    # TODO: Implement item selection (show on map, open detail panel, etc.)
    {:noreply, socket}
  end

  def handle_event("new_item", _params, socket) do
    # TODO: Implement new item creation modal
    {:noreply, put_flash(socket, :info, "New item creation coming soon")}
  end

  def handle_event("open_settings", _params, socket) do
    {:noreply, assign(socket, :show_settings_modal, true)}
  end

  def handle_event("close_settings", _params, socket) do
    {:noreply, assign(socket, :show_settings_modal, false)}
  end

  def handle_event("save_settings", params, socket) do
    view_type = Map.get(params, "view_type", socket.assigns.view_type)
    sort_field = Map.get(params, "sort_field", socket.assigns.sort_field)
    sort_direction = Map.get(params, "sort_direction", socket.assigns.sort_direction)
    default_filter = Map.get(params, "default_filter", "") |> String.trim()

    # Extract per-view visible fields
    visible_fields_list =
      extract_checkbox_fields(params, "visible_fields_list", socket.assigns.visible_fields_list)

    visible_fields_table =
      extract_checkbox_fields(params, "visible_fields_table", socket.assigns.visible_fields_table)

    visible_fields_card =
      extract_checkbox_fields(params, "visible_fields_card", socket.assigns.visible_fields_card)

    # Get the visible fields for the selected view type
    visible_fields =
      case view_type do
        "list" -> visible_fields_list
        "table" -> visible_fields_table
        "card" -> visible_fields_card
        _ -> visible_fields_list
      end

    # Save preferences if user is logged in
    current_user_id =
      if socket.assigns[:scope], do: socket.assigns.scope.current_user_id, else: nil

    if current_user_id do
      Datasets.update_user_preferences(current_user_id, socket.assigns.dataset.id, %{
        "view_type" => view_type,
        "sort_field" => sort_field,
        "sort_direction" => sort_direction,
        "visible_fields_list" => visible_fields_list,
        "visible_fields_table" => visible_fields_table,
        "visible_fields_card" => visible_fields_card,
        "default_filter" => default_filter
      })
    end

    # Reload items with new settings (apply default filter)
    filter_to_apply = if default_filter != "", do: default_filter, else: nil

    items =
      Datasets.list_dataset_items_paginated(socket.assigns.dataset.id,
        limit: 50,
        offset: 0,
        sort_field: sort_field,
        sort_direction: sort_direction,
        filter: filter_to_apply
      )

    total = Datasets.count_dataset_items(socket.assigns.dataset.id, filter_to_apply)

    {:noreply,
     socket
     |> assign(:view_type, view_type)
     |> assign(:sort_field, sort_field)
     |> assign(:sort_direction, sort_direction)
     |> assign(:visible_fields, visible_fields)
     |> assign(:visible_fields_list, visible_fields_list)
     |> assign(:visible_fields_table, visible_fields_table)
     |> assign(:visible_fields_card, visible_fields_card)
     |> assign(:default_filter, default_filter)
     |> assign(:quick_filter, default_filter)
     |> assign(:dataset_items, items)
     |> assign(:dataset_page, 0)
     |> assign(:dataset_has_more, length(items) == 50 && total > 50)
     |> assign(:dataset_total, total)
     |> assign(:show_settings_modal, false)}
  end

  def handle_event("reset_settings", _params, socket) do
    current_user_id =
      if socket.assigns[:scope], do: socket.assigns.scope.current_user_id, else: nil

    if current_user_id do
      Datasets.reset_user_preferences(current_user_id, socket.assigns.dataset.id)
    end

    # Reload with defaults
    dataset_slug = Datasets.dataset_name_to_slug(socket.assigns.dataset.name)
    prefs = Datasets.get_default_preferences(dataset_slug)
    default_filter = prefs["default_filter"] || ""

    total = Datasets.count_dataset_items(socket.assigns.dataset.id)

    items =
      Datasets.list_dataset_items_paginated(socket.assigns.dataset.id,
        limit: 50,
        offset: 0,
        sort_field: prefs["sort_field"],
        sort_direction: prefs["sort_direction"]
      )

    {:noreply,
     socket
     |> assign(:view_type, prefs["view_type"])
     |> assign(:sort_field, prefs["sort_field"])
     |> assign(:sort_direction, prefs["sort_direction"])
     |> assign(:visible_fields, prefs["visible_fields"])
     |> assign(:card_style, prefs["card_style"])
     |> assign(:default_filter, default_filter)
     |> assign(:quick_filter, default_filter)
     |> assign(:dataset_items, items)
     |> assign(:dataset_page, 0)
     |> assign(:dataset_has_more, length(items) == 50 && total > 50)
     |> assign(:dataset_total, total)
     |> assign(:show_settings_modal, false)}
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

  # Determine label for new item button based on dataset type
  defp new_item_label(nil), do: "New Item"
  defp new_item_label(%{name: "Points of Interest"}), do: "New POI"
  defp new_item_label(%{name: "Countries"}), do: "New Country"
  defp new_item_label(%{name: "Scenic Routes"}), do: "New Route"
  defp new_item_label(%{name: "Ferries"}), do: "New Ferry"
  defp new_item_label(%{name: "Shipping"}), do: "New Shipping"
  defp new_item_label(%{name: "Risk Regions"}), do: "New Region"
  defp new_item_label(_), do: "New Item"

  defp media_url(path) when is_binary(path) do
    base_url = Application.get_env(:grand_tour, :media)[:public_url]
    "#{base_url}/#{path}"
  end

  defp media_url(_), do: nil

  # Get available fields for a dataset based on its items' properties
  # Uses actual JSONB key names (camelCase for properties)
  defp get_dataset_fields(dataset) do
    # Common fields available in most datasets
    # Note: "name", "description", "rating" are top-level columns
    # Properties like "countryCode" are in the JSONB properties column
    base_fields = ["name", "description", "rating", "countryCode"]

    # Dataset-specific fields based on type
    type_fields =
      case Datasets.dataset_name_to_slug(dataset.name) do
        "pois" -> ["category", "country"]
        "countries" -> ["continent", "safetyRating", "drivingSide", "currencyCode"]
        "scenic-routes" -> ["distanceKm"]
        "ferries" -> ["fromPort", "toPort", "operator", "duration"]
        "shipping" -> ["fromPort", "toPort", "company", "routeType"]
        "risk-regions" -> ["riskLevel", "reason"]
        _ -> []
      end

    base_fields ++ type_fields
  end

  defp reload_with_filters(socket, active_filters) do
    # Build filter conditions for query
    items =
      Datasets.list_dataset_items_paginated(socket.assigns.dataset.id,
        limit: 50,
        offset: 0,
        sort_field: socket.assigns.sort_field,
        sort_direction: socket.assigns.sort_direction,
        filter: socket.assigns.quick_filter,
        filters: active_filters
      )

    total =
      Datasets.count_dataset_items(
        socket.assigns.dataset.id,
        socket.assigns.quick_filter,
        active_filters
      )

    socket
    |> assign(:dataset_items, items)
    |> assign(:dataset_page, 0)
    |> assign(:dataset_has_more, length(items) == 50 && total > 50)
    |> assign(:dataset_total, total)
  end

  defp extract_checkbox_fields(params, param_key, default) do
    fields =
      params
      |> Map.get(param_key, %{})
      |> Enum.filter(fn {_k, v} -> v == "true" end)
      |> Enum.map(fn {k, _v} -> k end)

    if fields == [], do: default, else: fields
  end
end
