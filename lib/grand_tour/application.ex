defmodule GrandTour.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GrandTourWeb.Telemetry,
      GrandTour.Repo,
      {DNSCluster, query: Application.get_env(:grand_tour, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GrandTour.PubSub},
      # Background job processing
      {Oban, Application.fetch_env!(:grand_tour, Oban)},
      # Start to serve requests, typically the last entry
      GrandTourWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GrandTour.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GrandTourWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
