defmodule GrandTourWeb.Router do
  use GrandTourWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GrandTourWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GrandTourWeb do
    pipe_through :browser

    live "/", AppLive

    live "/tours", TourLive.Index, :index
    live "/tours/new", TourLive.Index, :new
    live "/tours/:id/edit", TourLive.Index, :edit
    live "/tours/:id", TourLive.Show, :show
    live "/tours/:id/show/edit", TourLive.Show, :edit

    # Trip routes (nested under tour)
    live "/tours/:id/trips/new", TourLive.Show, :new_trip
    live "/tours/:id/trips/:trip_id/edit", TourLive.Show, :edit_trip
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
end
