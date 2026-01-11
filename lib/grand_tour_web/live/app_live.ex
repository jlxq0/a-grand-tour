defmodule GrandTourWeb.AppLive do
  use GrandTourWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    mapbox_token = Application.get_env(:grand_tour, :mapbox)[:access_token]

    {:ok,
     socket
     |> assign(:page_title, "A Grand Tour")
     |> assign(:active_tab, :overview)
     |> assign(:mapbox_token, mapbox_token)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="app-container" class="flex flex-col h-[calc(100vh-4rem)]">
        <%!-- Navigation Tabs --%>
        <nav class="tabs tabs-border border-b border-base-300 px-4 flex-shrink-0">
          <button
            phx-click="switch_tab"
            phx-value-tab="overview"
            class={["tab", @active_tab == :overview && "tab-active"]}
          >
            <.icon name="hero-globe-alt" class="w-4 h-4 mr-2" /> Overview
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
            phx-value-tab="trips"
            class={["tab", @active_tab == :trips && "tab-active"]}
          >
            <.icon name="hero-map" class="w-4 h-4 mr-2" /> Trips
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="documents"
            class={["tab", @active_tab == :documents && "tab-active"]}
          >
            <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> Documents
          </button>
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
              class="absolute inset-0"
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
              <.tab_content tab={@active_tab} />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Tab content component
  defp tab_content(%{tab: :overview} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <h1>A Grand Tour</h1>
      <p class="lead text-lg text-base-content/70">
        Your 13-year overland expedition around the world.
      </p>

      <div class="stats stats-vertical lg:stats-horizontal shadow w-full mt-6">
        <div class="stat">
          <div class="stat-title">Countries</div>
          <div class="stat-value">100+</div>
          <div class="stat-desc">Across 6 continents</div>
        </div>
        <div class="stat">
          <div class="stat-title">Distance</div>
          <div class="stat-value">200k</div>
          <div class="stat-desc">Kilometers by road</div>
        </div>
        <div class="stat">
          <div class="stat-title">Duration</div>
          <div class="stat-value">13</div>
          <div class="stat-desc">Years of adventure</div>
        </div>
      </div>

      <h2 class="mt-8">Getting Started</h2>
      <p>
        This is your trip planning dashboard. Use the tabs above to navigate between different views:
      </p>
      <ul>
        <li><strong>Overview</strong> - Summary and quick stats</li>
        <li><strong>Timeline</strong> - Visual timeline of all trips</li>
        <li><strong>Trips</strong> - Manage individual trips and routes</li>
        <li><strong>Documents</strong> - Trip notes, guides, and references</li>
      </ul>
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
      <div class="alert alert-info mt-4">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>Timeline view coming in Phase 4.4</span>
      </div>
    </div>
    """
  end

  defp tab_content(%{tab: :trips} = assigns) do
    ~H"""
    <div class="prose max-w-none">
      <h1>Trips</h1>
      <p class="text-base-content/70">
        Manage your trips and routes here.
      </p>
      <div class="alert alert-info mt-4">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>Trip management coming in Phase 2.2</span>
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
      <div class="alert alert-info mt-4">
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>Document management coming in Phase 3.3</span>
      </div>
    </div>
    """
  end

  defp tab_content(assigns) do
    ~H"""
    <div class="alert alert-warning">
      <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
      <span>Unknown tab</span>
    </div>
    """
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("map_loaded", _params, socket) do
    # Map is ready - could load initial data here
    {:noreply, socket}
  end

  @impl true
  def handle_event("map_clicked", %{"lng" => lng, "lat" => lat}, socket) do
    # Handle map clicks - for now just log
    IO.inspect({lng, lat}, label: "Map clicked at")
    {:noreply, socket}
  end
end
