# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GrandTour.Repo.insert!(%GrandTour.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias GrandTour.Accounts
alias GrandTour.Tours

# Create a dummy user for development
dummy_email = "demo@a-grand-tour.com"

user =
  case Accounts.get_user_by_email(dummy_email) do
    nil ->
      {:ok, user} = Accounts.register_user(%{email: dummy_email})
      IO.puts("Created dummy user: #{dummy_email}")
      user

    user ->
      IO.puts("Dummy user already exists: #{dummy_email}")
      user
  end

# Create a sample tour for the dummy user
scope = Accounts.Scope.for_user(user)

case Tours.list_tours(scope) do
  [] ->
    {:ok, tour} =
      Tours.create_tour(scope, %{
        name: "My Grand Tour",
        subtitle: "An epic overland journey around the world",
        is_public: false
      })

    IO.puts("Created sample tour: #{tour.name}")

    # Create some sample trips
    {:ok, _trip1} =
      Tours.create_trip(tour, %{
        name: "Europe",
        subtitle: "Starting from the UK through Western Europe",
        status: "planning"
      })

    {:ok, _trip2} =
      Tours.create_trip(tour, %{
        name: "Middle East",
        subtitle: "Turkey, Iran, and the Gulf States",
        status: "planning"
      })

    {:ok, _trip3} =
      Tours.create_trip(tour, %{
        name: "South Asia",
        subtitle: "India, Nepal, and beyond",
        status: "planning"
      })

    IO.puts("Created #{3} sample trips")

  tours ->
    IO.puts("Sample data already exists: #{length(tours)} tour(s)")
end
