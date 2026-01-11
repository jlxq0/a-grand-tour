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

  # Public routes (landing page)
  scope "/", GrandTourWeb do
    pipe_through :browser

    live "/", LandingLive, :index
  end

  # Protected routes (require authentication)
  scope "/", GrandTourWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated, on_mount: [{GrandTourWeb.UserAuth, :ensure_authenticated}] do
      live "/tours", TourLive.Index, :index
      live "/tours/new", TourLive.Index, :new
      live "/tours/:id/edit", TourLive.Index, :edit

      # Tour detail with split-screen map view
      live "/tours/:id", AppLive, :show
      live "/tours/:id/trips/new", AppLive, :new_trip
      live "/tours/:id/trips/:trip_id/edit", AppLive, :edit_trip
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", GrandTourWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:grand_tour, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GrandTourWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

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
end
