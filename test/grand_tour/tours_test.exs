defmodule GrandTour.ToursTest do
  use GrandTour.DataCase

  alias GrandTour.Tours
  alias GrandTour.Tours.Tour

  describe "tours" do
    @valid_attrs %{name: "My Grand Tour", subtitle: "An epic journey", is_public: false}
    @update_attrs %{name: "Updated Tour", subtitle: "New description", is_public: true}
    @invalid_attrs %{name: nil, subtitle: nil, is_public: nil}

    def tour_fixture(attrs \\ %{}) do
      {:ok, tour} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tours.create_tour()

      tour
    end

    test "list_tours/0 returns all tours" do
      tour = tour_fixture()
      assert Tours.list_tours() == [tour]
    end

    test "list_tours/0 returns multiple tours" do
      tour1 = tour_fixture(%{name: "First Tour"})
      tour2 = tour_fixture(%{name: "Second Tour"})

      tours = Tours.list_tours()
      assert length(tours) == 2
      assert Enum.any?(tours, &(&1.id == tour1.id))
      assert Enum.any?(tours, &(&1.id == tour2.id))
    end

    test "list_public_tours/0 returns only public tours" do
      _private_tour = tour_fixture(%{name: "Private", is_public: false})
      public_tour = tour_fixture(%{name: "Public", is_public: true})

      assert Tours.list_public_tours() == [public_tour]
    end

    test "get_tour!/1 returns the tour with given id" do
      tour = tour_fixture()
      assert Tours.get_tour!(tour.id) == tour
    end

    test "get_tour!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Tours.get_tour!(Ecto.UUID.generate())
      end
    end

    test "get_tour/1 returns the tour with given id" do
      tour = tour_fixture()
      assert Tours.get_tour(tour.id) == tour
    end

    test "get_tour/1 returns nil for non-existent id" do
      assert Tours.get_tour(Ecto.UUID.generate()) == nil
    end

    test "create_tour/1 with valid data creates a tour" do
      assert {:ok, %Tour{} = tour} = Tours.create_tour(@valid_attrs)
      assert tour.name == "My Grand Tour"
      assert tour.subtitle == "An epic journey"
      assert tour.is_public == false
    end

    test "create_tour/1 with minimal valid data creates a tour" do
      assert {:ok, %Tour{} = tour} = Tours.create_tour(%{name: "Minimal Tour"})
      assert tour.name == "Minimal Tour"
      assert tour.subtitle == nil
      assert tour.is_public == false
    end

    test "create_tour/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tours.create_tour(@invalid_attrs)
    end

    test "create_tour/1 with empty name returns error changeset" do
      assert {:error, %Ecto.Changeset{} = changeset} = Tours.create_tour(%{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_tour/1 with name too long returns error changeset" do
      long_name = String.duplicate("a", 256)
      assert {:error, %Ecto.Changeset{} = changeset} = Tours.create_tour(%{name: long_name})
      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "update_tour/2 with valid data updates the tour" do
      tour = tour_fixture()
      assert {:ok, %Tour{} = tour} = Tours.update_tour(tour, @update_attrs)
      assert tour.name == "Updated Tour"
      assert tour.subtitle == "New description"
      assert tour.is_public == true
    end

    test "update_tour/2 with invalid data returns error changeset" do
      tour = tour_fixture()
      assert {:error, %Ecto.Changeset{}} = Tours.update_tour(tour, @invalid_attrs)
      assert tour == Tours.get_tour!(tour.id)
    end

    test "delete_tour/1 deletes the tour" do
      tour = tour_fixture()
      assert {:ok, %Tour{}} = Tours.delete_tour(tour)
      assert_raise Ecto.NoResultsError, fn -> Tours.get_tour!(tour.id) end
    end

    test "change_tour/1 returns a tour changeset" do
      tour = tour_fixture()
      assert %Ecto.Changeset{} = Tours.change_tour(tour)
    end

    test "change_tour/2 with attrs returns a tour changeset" do
      tour = tour_fixture()
      changeset = Tours.change_tour(tour, %{name: "New Name"})
      assert %Ecto.Changeset{} = changeset
      assert Ecto.Changeset.get_field(changeset, :name) == "New Name"
    end
  end
end
