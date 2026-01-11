defmodule GrandTour.Repo do
  use Ecto.Repo,
    otp_app: :grand_tour,
    adapter: Ecto.Adapters.Postgres
end
