defmodule GrandTourWeb.LandingLive do
  use GrandTourWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "A Grand Tour - Plan Your Epic Journey")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen">
        <div class="hero min-h-[70vh] bg-gradient-to-br from-primary/10 to-secondary/10">
          <div class="hero-content text-center">
            <div class="max-w-2xl">
              <h1 class="text-5xl font-bold">A Grand Tour</h1>
              <p class="py-6 text-xl text-base-content/70">
                Plan your epic overland journey around the world. Create detailed itineraries,
                manage routes, and document your adventures.
              </p>
              <div class="flex gap-4 justify-center">
                <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg">
                  Get Started
                </.link>
                <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-lg">
                  Sign In
                </.link>
              </div>
            </div>
          </div>
        </div>

        <div class="container mx-auto px-4 py-16">
          <div class="grid md:grid-cols-3 gap-8">
            <div class="card bg-base-200">
              <div class="card-body items-center text-center">
                <.icon name="hero-map" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Interactive Maps</h2>
                <p class="text-base-content/70">
                  Visualize your route on a beautiful globe. Plan waypoints, ferries, and flights.
                </p>
              </div>
            </div>

            <div class="card bg-base-200">
              <div class="card-body items-center text-center">
                <.icon name="hero-calendar-days" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Trip Planning</h2>
                <p class="text-base-content/70">
                  Organize your journey into trips with detailed itineraries and schedules.
                </p>
              </div>
            </div>

            <div class="card bg-base-200">
              <div class="card-body items-center text-center">
                <.icon name="hero-document-text" class="w-12 h-12 text-primary" />
                <h2 class="card-title">Documentation</h2>
                <p class="text-base-content/70">
                  Create rich documents with country info, visa requirements, and travel notes.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-base-200 py-16">
          <div class="container mx-auto px-4 text-center">
            <h2 class="text-3xl font-bold mb-4">Ready to Start Your Adventure?</h2>
            <p class="text-base-content/70 mb-8 max-w-xl mx-auto">
              Join travelers who use A Grand Tour to plan their overland expeditions.
            </p>
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg">
              Create Your First Tour
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
