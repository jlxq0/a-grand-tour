alias GrandTour.Repo
alias GrandTour.Accounts
alias GrandTour.Accounts.Scope
alias GrandTour.Tours

import Ecto.Query

# Find or create the demo user
demo_email = "demo@a-grand-tour.com"

user =
  case Repo.get_by(Accounts.User, email: demo_email) do
    nil ->
      {:ok, user} = Accounts.register_user(%{email: demo_email})
      user

    user ->
      user
  end

scope = Scope.for_user(user)

# Delete existing tours for clean slate
from(t in GrandTour.Tours.Tour, where: t.user_id == ^user.id)
|> Repo.delete_all()

# Create demo tours
tours = [
  %{
    name: "My Grand Tour",
    subtitle: "An epic overland journey around the world",
    cover_image: "/images/tours/tour-1.jpg",
    is_public: false
  },
  %{
    name: "Pan-American Highway",
    subtitle: "From Alaska to Tierra del Fuego",
    cover_image: "/images/tours/tour-2.jpg",
    is_public: true
  },
  %{
    name: "Silk Road Adventure",
    subtitle: "Following ancient trade routes through Central Asia",
    cover_image: "/images/tours/tour-3.jpg",
    is_public: false
  },
  %{
    name: "African Odyssey",
    subtitle: "Cape Town to Cairo overland expedition",
    cover_image: "/images/tours/tour-4.jpg",
    is_public: true
  }
]

for tour_attrs <- tours do
  {:ok, _tour} = Tours.create_tour(scope, tour_attrs)
  IO.puts("Created tour: #{tour_attrs.name}")
end

IO.puts("\nCreated #{length(tours)} demo tours for #{demo_email}")
