defmodule GrandTour.TripsTest do
  use GrandTour.DataCase

  alias GrandTour.Tours
  alias GrandTour.Tours.Trip

  describe "trips" do
    @valid_attrs %{name: "European Leg", subtitle: "Through Western Europe"}
    @update_attrs %{name: "Updated Trip", subtitle: "New description", status: "active"}
    @invalid_attrs %{name: nil}

    def tour_fixture(attrs \\ %{}) do
      {:ok, tour} =
        attrs
        |> Enum.into(%{name: "My Grand Tour"})
        |> Tours.create_tour()

      tour
    end

    def trip_fixture(tour, attrs \\ %{}) do
      {:ok, trip} =
        attrs
        |> Enum.into(@valid_attrs)
        |> then(&Tours.create_trip(tour, &1))

      trip
    end

    test "list_trips/1 returns all trips for a tour ordered by position" do
      tour = tour_fixture()
      trip1 = trip_fixture(tour, %{name: "First"})
      trip2 = trip_fixture(tour, %{name: "Second"})
      trip3 = trip_fixture(tour, %{name: "Third"})

      assert Tours.list_trips(tour) == [trip1, trip2, trip3]
    end

    test "list_trips/1 returns empty list for tour with no trips" do
      tour = tour_fixture()
      assert Tours.list_trips(tour) == []
    end

    test "list_trips/1 only returns trips for the specified tour" do
      tour1 = tour_fixture(%{name: "Tour 1"})
      tour2 = tour_fixture(%{name: "Tour 2"})

      trip1 = trip_fixture(tour1, %{name: "Trip for Tour 1"})
      _trip2 = trip_fixture(tour2, %{name: "Trip for Tour 2"})

      assert Tours.list_trips(tour1) == [trip1]
    end

    test "get_trip!/1 returns the trip with given id" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert Tours.get_trip!(trip.id) == trip
    end

    test "get_trip!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Tours.get_trip!(Ecto.UUID.generate())
      end
    end

    test "get_trip/1 returns the trip with given id" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert Tours.get_trip(trip.id) == trip
    end

    test "get_trip/1 returns nil for non-existent id" do
      assert Tours.get_trip(Ecto.UUID.generate()) == nil
    end

    test "get_trip_with_tour!/1 returns trip with tour preloaded" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      result = Tours.get_trip_with_tour!(trip.id)
      assert result.id == trip.id
      assert result.tour.id == tour.id
    end

    test "create_trip/2 with valid data creates a trip" do
      tour = tour_fixture()
      assert {:ok, %Trip{} = trip} = Tours.create_trip(tour, @valid_attrs)
      assert trip.name == "European Leg"
      assert trip.subtitle == "Through Western Europe"
      assert trip.status == "planning"
      assert trip.position == 1
      assert trip.tour_id == tour.id
    end

    test "create_trip/2 auto-increments position" do
      tour = tour_fixture()
      {:ok, trip1} = Tours.create_trip(tour, %{name: "First"})
      {:ok, trip2} = Tours.create_trip(tour, %{name: "Second"})
      {:ok, trip3} = Tours.create_trip(tour, %{name: "Third"})

      assert trip1.position == 1
      assert trip2.position == 2
      assert trip3.position == 3
    end

    test "create_trip/2 with minimal valid data creates a trip" do
      tour = tour_fixture()
      assert {:ok, %Trip{} = trip} = Tours.create_trip(tour, %{name: "Minimal Trip"})
      assert trip.name == "Minimal Trip"
      assert trip.subtitle == nil
      assert trip.start_date == nil
      assert trip.end_date == nil
    end

    test "create_trip/2 with dates creates a trip" do
      tour = tour_fixture()

      attrs = %{
        name: "Dated Trip",
        start_date: ~D[2027-02-01],
        end_date: ~D[2027-04-15]
      }

      assert {:ok, %Trip{} = trip} = Tours.create_trip(tour, attrs)
      assert trip.start_date == ~D[2027-02-01]
      assert trip.end_date == ~D[2027-04-15]
    end

    test "create_trip/2 with invalid data returns error changeset" do
      tour = tour_fixture()
      assert {:error, %Ecto.Changeset{}} = Tours.create_trip(tour, @invalid_attrs)
    end

    test "create_trip/2 with empty name returns error changeset" do
      tour = tour_fixture()
      assert {:error, %Ecto.Changeset{} = changeset} = Tours.create_trip(tour, %{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_trip/2 with invalid status returns error changeset" do
      tour = tour_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Tours.create_trip(tour, %{name: "Trip", status: "invalid"})

      assert "is invalid" in errors_on(changeset).status
    end

    test "create_trip/2 with end_date before start_date returns error" do
      tour = tour_fixture()

      attrs = %{
        name: "Bad dates",
        start_date: ~D[2027-04-15],
        end_date: ~D[2027-02-01]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Tours.create_trip(tour, attrs)
      assert "must be after start date" in errors_on(changeset).end_date
    end

    test "update_trip/2 with valid data updates the trip" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert {:ok, %Trip{} = trip} = Tours.update_trip(trip, @update_attrs)
      assert trip.name == "Updated Trip"
      assert trip.subtitle == "New description"
      assert trip.status == "active"
    end

    test "update_trip/2 with invalid data returns error changeset" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert {:error, %Ecto.Changeset{}} = Tours.update_trip(trip, @invalid_attrs)
      assert trip == Tours.get_trip!(trip.id)
    end

    test "delete_trip/1 deletes the trip" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert {:ok, %Trip{}} = Tours.delete_trip(trip)
      assert_raise Ecto.NoResultsError, fn -> Tours.get_trip!(trip.id) end
    end

    test "delete_trip/1 reorders remaining trips" do
      tour = tour_fixture()
      trip1 = trip_fixture(tour, %{name: "First"})
      trip2 = trip_fixture(tour, %{name: "Second"})
      trip3 = trip_fixture(tour, %{name: "Third"})

      assert trip1.position == 1
      assert trip2.position == 2
      assert trip3.position == 3

      # Delete the middle trip
      {:ok, _} = Tours.delete_trip(trip2)

      # Remaining trips should be reordered
      updated_trip1 = Tours.get_trip!(trip1.id)
      updated_trip3 = Tours.get_trip!(trip3.id)

      assert updated_trip1.position == 1
      assert updated_trip3.position == 2
    end

    test "change_trip/1 returns a trip changeset" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      assert %Ecto.Changeset{} = Tours.change_trip(trip)
    end

    test "change_trip/2 with attrs returns a trip changeset" do
      tour = tour_fixture()
      trip = trip_fixture(tour)
      changeset = Tours.change_trip(trip, %{name: "New Name"})
      assert %Ecto.Changeset{} = changeset
      assert Ecto.Changeset.get_field(changeset, :name) == "New Name"
    end

    test "reorder_trips/2 updates positions" do
      tour = tour_fixture()
      trip1 = trip_fixture(tour, %{name: "First"})
      trip2 = trip_fixture(tour, %{name: "Second"})
      trip3 = trip_fixture(tour, %{name: "Third"})

      # Reorder to [trip3, trip1, trip2]
      :ok = Tours.reorder_trips(tour, [trip3.id, trip1.id, trip2.id])

      assert Tours.get_trip!(trip3.id).position == 1
      assert Tours.get_trip!(trip1.id).position == 2
      assert Tours.get_trip!(trip2.id).position == 3
    end

    test "move_trip/2 moves trip up" do
      tour = tour_fixture()
      trip1 = trip_fixture(tour, %{name: "First"})
      trip2 = trip_fixture(tour, %{name: "Second"})
      trip3 = trip_fixture(tour, %{name: "Third"})

      # Move trip3 to position 1
      {:ok, moved} = Tours.move_trip(trip3, 1)

      assert moved.position == 1
      assert Tours.get_trip!(trip1.id).position == 2
      assert Tours.get_trip!(trip2.id).position == 3
    end

    test "move_trip/2 moves trip down" do
      tour = tour_fixture()
      trip1 = trip_fixture(tour, %{name: "First"})
      trip2 = trip_fixture(tour, %{name: "Second"})
      trip3 = trip_fixture(tour, %{name: "Third"})

      # Move trip1 to position 3
      {:ok, moved} = Tours.move_trip(trip1, 3)

      assert moved.position == 3
      assert Tours.get_trip!(trip2.id).position == 1
      assert Tours.get_trip!(trip3.id).position == 2
    end

    test "move_trip/2 with same position returns unchanged trip" do
      tour = tour_fixture()
      trip = trip_fixture(tour)

      {:ok, result} = Tours.move_trip(trip, trip.position)
      assert result.position == trip.position
    end
  end
end
