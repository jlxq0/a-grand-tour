defmodule GrandTourWeb.LandingLive do
  use GrandTourWeb, :live_view

  on_mount {GrandTourWeb.UserAuth, :mount_current_scope}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "A Grand Tour - Plan Your Epic Journey")
     |> assign(:hide_user_bar, true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <%!-- Floating theme toggle --%>
      <div class="fixed top-4 right-4 z-50">
        <.theme_toggle />
      </div>

      <%!-- Hero Section with Background Image --%>
      <div class="relative min-h-[80vh] flex items-center justify-center">
        <%!-- Background Image - Light mode (Roozbeh) --%>
        <div
          class="absolute inset-0 bg-cover bg-center bg-no-repeat dark:hidden"
          style="background-image: url('/images/hero_roozbeh_eslami_deLkLeJDAMc.webp');"
        >
        </div>
        <%!-- Background Image - Dark mode (John Towner) --%>
        <div
          class="absolute inset-0 bg-cover bg-center bg-no-repeat hidden dark:block"
          style="background-image: url('/images/hero_john_towner_3Kv48NS4WUU.webp');"
        >
        </div>
        <%!-- Overlay for text readability --%>
        <div class="absolute inset-0 bg-gradient-to-b from-black/40 via-black/20 to-black/60"></div>

        <%!-- Hero Content --%>
        <div class="relative z-10 text-center px-4 max-w-4xl mx-auto">
          <h1 class="text-6xl md:text-8xl font-bold text-white/90 mb-6">
            A Grand Tour
          </h1>
          <p class="text-xl md:text-2xl text-white/90 drop-shadow mb-8 leading-relaxed">
            Plan your epic overland journey around the world. Create detailed itineraries,
            manage routes, and document your adventures.
          </p>
          <div class="flex gap-4 justify-center flex-wrap">
            <%= if @current_scope && @current_scope.user do %>
              <.link navigate={~p"/tours"} class="btn btn-primary btn-lg">
                Show My Tours
              </.link>
            <% else %>
              <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg">
                Get Started
              </.link>
              <.link
                navigate={~p"/users/log-in"}
                class="btn btn-ghost btn-lg text-white border-white/50 hover:bg-white/20"
              >
                Sign In
              </.link>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Features Section --%>
      <div class="bg-base-100 py-20">
        <div class="container mx-auto px-4">
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <%!-- Interactive Maps --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-map" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Interactive Maps</h2>
                <p class="text-base-content/70">
                  Visualize your route on a beautiful 3D globe. Plan waypoints, ferries, and flights with ease.
                </p>
              </div>
            </div>

            <%!-- Trip Planning --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-calendar-days" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Trip Planning</h2>
                <p class="text-base-content/70">
                  Organize your journey into trips with detailed itineraries, schedules, and budgets.
                </p>
              </div>
            </div>

            <%!-- Documentation --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-document-text" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Documentation</h2>
                <p class="text-base-content/70">
                  Create rich documents with country info, visa requirements, and travel notes.
                </p>
              </div>
            </div>

            <%!-- Public Website --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-globe-alt" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Public Website</h2>
                <p class="text-base-content/70">
                  Share your adventure with friends and family. Publish your tour as a beautiful public page.
                </p>
              </div>
            </div>

            <%!-- Collaboration --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-user-group" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Collaboration</h2>
                <p class="text-base-content/70">
                  Invite travel companions to help plan. Work together in real-time on routes and itineraries.
                </p>
              </div>
            </div>

            <%!-- Offline Access --%>
            <div class="card bg-base-200 hover:shadow-lg transition-shadow">
              <div class="card-body items-center text-center">
                <.icon name="hero-device-phone-mobile" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Offline Access</h2>
                <p class="text-base-content/70">
                  Access your plans anywhere with our iOS app. Download maps and documents for offline use.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Footer --%>
      <footer class="footer footer-center p-10 bg-base-300 text-base-content">
        <nav class="grid grid-flow-col gap-6">
          <a class="link link-hover">About</a>
          <a class="link link-hover">Features</a>
          <a class="link link-hover">Pricing</a>
          <a class="link link-hover">Contact</a>
        </nav>
        <nav class="grid grid-flow-col gap-6">
          <a class="link link-hover">Privacy Policy</a>
          <a class="link link-hover">Terms of Service</a>
        </nav>
        <aside>
          <p>© {Date.utc_today().year} A Grand Tour. All rights reserved.</p>
        </aside>
      </footer>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  # Theme toggle component (copied from Layouts for standalone use)
  defp theme_toggle(assigns) do
    ~H"""
    <div class="group relative flex flex-row items-center border border-white/10 bg-white/5 backdrop-blur-sm rounded-full opacity-40 hover:opacity-100 hover:bg-white/10 hover:border-white/20 transition-all duration-200">
      <div class="absolute w-1/3 h-full rounded-full bg-white/20 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] opacity-0 group-hover:opacity-100" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon
          name="hero-computer-desktop-micro"
          class="size-4 text-white/50 group-hover:text-white/90 transition-colors"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 text-white/50 group-hover:text-white/90 transition-colors" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 text-white/50 group-hover:text-white/90 transition-colors" />
      </button>
    </div>
    """
  end

  defp flash_group(assigns) do
    ~H"""
    <div id="flash-group" class="fixed top-4 right-20 z-50" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end
end
