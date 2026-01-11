defmodule GrandTour.ToursTest do
  use GrandTour.DataCase

  alias GrandTour.Tours
  alias GrandTour.Tours.Tour

  import GrandTour.AccountsFixtures

  describe "tours" do
    @valid_attrs %{name: "My Grand Tour", subtitle: "An epic journey", is_public: false}
    @update_attrs %{name: "Updated Tour", subtitle: "New description", is_public: true}
    @invalid_attrs %{name: nil, subtitle: nil, is_public: nil}

    setup do
      scope = user_scope_fixture()
      %{scope: scope}
    end

    def tour_fixture(scope, attrs \\ %{}) do
      {:ok, tour} =
        attrs
        |> Enum.into(@valid_attrs)
        |> then(&Tours.create_tour(scope, &1))

      tour
    end

    test "list_tours/1 returns all tours for user", %{scope: scope} do
      tour = tour_fixture(scope)
      assert Tours.list_tours(scope) == [tour]
    end

    test "list_tours/1 returns multiple tours", %{scope: scope} do
      tour1 = tour_fixture(scope, %{name: "First Tour"})
      tour2 = tour_fixture(scope, %{name: "Second Tour"})

      tours = Tours.list_tours(scope)
      assert length(tours) == 2
      assert Enum.any?(tours, &(&1.id == tour1.id))
      assert Enum.any?(tours, &(&1.id == tour2.id))
    end

    test "list_tours/1 only returns tours for the specified user", %{scope: scope} do
      tour = tour_fixture(scope)

      # Create another user's tour
      other_scope = user_scope_fixture()
      _other_tour = tour_fixture(other_scope, %{name: "Other User Tour"})

      tours = Tours.list_tours(scope)
      assert length(tours) == 1
      assert hd(tours).id == tour.id
    end

    test "list_public_tours/0 returns only public tours", %{scope: scope} do
      _private_tour = tour_fixture(scope, %{name: "Private", is_public: false})
      public_tour = tour_fixture(scope, %{name: "Public", is_public: true})

      assert Tours.list_public_tours() == [public_tour]
    end

    test "get_tour!/2 returns the tour with given id for user", %{scope: scope} do
      tour = tour_fixture(scope)
      assert Tours.get_tour!(scope, tour.id) == tour
    end

    test "get_tour!/2 raises for non-existent id", %{scope: scope} do
      assert_raise Ecto.NoResultsError, fn ->
        Tours.get_tour!(scope, Ecto.UUID.generate())
      end
    end

    test "get_tour!/2 raises for other user's tour", %{scope: scope} do
      other_scope = user_scope_fixture()
      other_tour = tour_fixture(other_scope)

      assert_raise Ecto.NoResultsError, fn ->
        Tours.get_tour!(scope, other_tour.id)
      end
    end

    test "get_tour/2 returns the tour with given id", %{scope: scope} do
      tour = tour_fixture(scope)
      assert Tours.get_tour(scope, tour.id) == tour
    end

    test "get_tour/2 returns nil for non-existent id", %{scope: scope} do
      assert Tours.get_tour(scope, Ecto.UUID.generate()) == nil
    end

    test "get_tour/2 returns nil for other user's tour", %{scope: scope} do
      other_scope = user_scope_fixture()
      other_tour = tour_fixture(other_scope)

      assert Tours.get_tour(scope, other_tour.id) == nil
    end

    test "create_tour/2 with valid data creates a tour", %{scope: scope} do
      assert {:ok, %Tour{} = tour} = Tours.create_tour(scope, @valid_attrs)
      assert tour.name == "My Grand Tour"
      assert tour.subtitle == "An epic journey"
      assert tour.is_public == false
      assert tour.user_id == scope.user.id
    end

    test "create_tour/2 with minimal valid data creates a tour", %{scope: scope} do
      assert {:ok, %Tour{} = tour} = Tours.create_tour(scope, %{name: "Minimal Tour"})
      assert tour.name == "Minimal Tour"
      assert tour.subtitle == nil
      assert tour.is_public == false
    end

    test "create_tour/2 with invalid data returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Tours.create_tour(scope, @invalid_attrs)
    end

    test "create_tour/2 with empty name returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{} = changeset} = Tours.create_tour(scope, %{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_tour/2 with name too long returns error changeset", %{scope: scope} do
      long_name = String.duplicate("a", 256)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Tours.create_tour(scope, %{name: long_name})

      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "update_tour/2 with valid data updates the tour", %{scope: scope} do
      tour = tour_fixture(scope)
      assert {:ok, %Tour{} = tour} = Tours.update_tour(tour, @update_attrs)
      assert tour.name == "Updated Tour"
      assert tour.subtitle == "New description"
      assert tour.is_public == true
    end

    test "update_tour/2 with invalid data returns error changeset", %{scope: scope} do
      tour = tour_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tours.update_tour(tour, @invalid_attrs)
      assert tour == Tours.get_tour!(scope, tour.id)
    end

    test "delete_tour/1 deletes the tour", %{scope: scope} do
      tour = tour_fixture(scope)
      assert {:ok, %Tour{}} = Tours.delete_tour(tour)
      assert_raise Ecto.NoResultsError, fn -> Tours.get_tour!(scope, tour.id) end
    end

    test "change_tour/1 returns a tour changeset", %{scope: scope} do
      tour = tour_fixture(scope)
      assert %Ecto.Changeset{} = Tours.change_tour(tour)
    end

    test "change_tour/2 with attrs returns a tour changeset", %{scope: scope} do
      tour = tour_fixture(scope)
      changeset = Tours.change_tour(tour, %{name: "New Name"})
      assert %Ecto.Changeset{} = changeset
      assert Ecto.Changeset.get_field(changeset, :name) == "New Name"
    end
  end
end
