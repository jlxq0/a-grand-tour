defmodule GrandTourWeb.Router do
  use GrandTourWeb, :router

  import GrandTourWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GrandTourWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
    plug :require_authenticated_user_api
  end

  # Media API routes (authenticated JSON endpoints)
  scope "/api", GrandTourWeb do
    pipe_through :authenticated_api

    post "/media/presign-upload", MediaController, :presign_upload
    get "/media/presign-download", MediaController, :presign_download
  end

  # Public routes (landing page)
  scope "/", GrandTourWeb do
    pipe_through :browser

    live "/", LandingLive, :index
  end

  ## Authentication routes - MUST come before dynamic username routes
  scope "/", GrandTourWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", GrandTourWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", GrandTourWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:grand_tour, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GrandTourWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Protected routes (require authentication) - Dynamic routes last
  scope "/", GrandTourWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated, on_mount: [{GrandTourWeb.UserAuth, :ensure_authenticated}] do
      # Redirect old /tours route to user's tours list
      live "/tours", TourLive.Index, :index

      # User-scoped routes (new URL schema)
      # User's tours list
      live "/:username/tours", TourLive.Index, :index
      live "/:username/tours/new", TourLive.Index, :new

      # Tour overview and edit
      live "/:username/:tour_slug", AppLive, :overview
      live "/:username/:tour_slug/edit", AppLive, :edit_tour

      # Timeline
      live "/:username/:tour_slug/timeline", AppLive, :timeline

      # Trips
      live "/:username/:tour_slug/trips/new", AppLive, :new_trip
      live "/:username/:tour_slug/trips/:trip_slug", AppLive, :trip
      live "/:username/:tour_slug/trips/:trip_slug/edit", AppLive, :edit_trip

      # Datasets
      live "/:username/:tour_slug/datasets/new", AppLive, :new_dataset
      live "/:username/:tour_slug/datasets/:dataset_id", AppLive, :dataset

      # Documents
      live "/:username/:tour_slug/documents", AppLive, :documents
    end
  end
end
