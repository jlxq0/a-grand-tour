defmodule GrandTour.DatasetsTest do
  use GrandTour.DataCase

  alias GrandTour.Datasets
  alias GrandTour.Datasets.Dataset
  alias GrandTour.Datasets.DatasetItem
  alias GrandTour.Datasets.TourOverride
  alias GrandTour.Datasets.TourAddition
  alias GrandTour.Tours

  import GrandTour.AccountsFixtures

  # ===========================================================================
  # Setup Helpers
  # ===========================================================================

  defp create_tour do
    scope = user_scope_fixture()
    {:ok, tour} = Tours.create_tour(scope, %{name: "Test Tour"})
    %{tour: tour, scope: scope}
  end

  defp create_system_dataset(attrs \\ %{}) do
    {:ok, dataset} =
      attrs
      |> Enum.into(%{name: "POIs", geometry_type: "point"})
      |> Datasets.create_system_dataset()

    dataset
  end

  defp create_tour_dataset(tour_id, attrs) do
    {:ok, dataset} =
      attrs
      |> Enum.into(%{name: "My Custom List", geometry_type: "point"})
      |> then(&Datasets.create_tour_dataset(tour_id, &1))

    dataset
  end

  # ===========================================================================
  # Datasets Tests
  # ===========================================================================

  describe "datasets" do
    test "list_system_datasets/0 returns all system datasets" do
      dataset1 = create_system_dataset(%{name: "POIs", position: 1})
      dataset2 = create_system_dataset(%{name: "Scenic Routes", position: 2})

      datasets = Datasets.list_system_datasets()
      assert length(datasets) == 2
      assert Enum.map(datasets, & &1.id) == [dataset1.id, dataset2.id]
    end

    test "list_system_datasets/0 returns datasets ordered by position" do
      _dataset2 = create_system_dataset(%{name: "Second", position: 2})
      _dataset1 = create_system_dataset(%{name: "First", position: 1})
      _dataset3 = create_system_dataset(%{name: "Third", position: 3})

      datasets = Datasets.list_system_datasets()
      assert Enum.map(datasets, & &1.name) == ["First", "Second", "Third"]
    end

    test "list_tour_datasets/1 returns only user datasets for a tour" do
      %{tour: tour} = create_tour()
      _system_dataset = create_system_dataset()
      user_dataset = create_tour_dataset(tour.id, %{name: "My List"})

      datasets = Datasets.list_tour_datasets(tour.id)
      assert length(datasets) == 1
      assert hd(datasets).id == user_dataset.id
    end

    test "list_all_datasets/1 returns system datasets + user datasets for a tour" do
      %{tour: tour} = create_tour()
      system_dataset = create_system_dataset(%{name: "System POIs"})
      user_dataset = create_tour_dataset(tour.id, %{name: "My List"})

      datasets = Datasets.list_all_datasets(tour.id)
      assert length(datasets) == 2
      ids = Enum.map(datasets, & &1.id)
      assert system_dataset.id in ids
      assert user_dataset.id in ids
    end

    test "get_dataset!/1 returns the dataset with given id" do
      dataset = create_system_dataset()
      assert Datasets.get_dataset!(dataset.id) == dataset
    end

    test "get_dataset!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Datasets.get_dataset!(Ecto.UUID.generate())
      end
    end

    test "create_system_dataset/1 creates a system dataset" do
      attrs = %{name: "World POIs", description: "All POIs", geometry_type: "point"}
      assert {:ok, %Dataset{} = dataset} = Datasets.create_system_dataset(attrs)
      assert dataset.name == "World POIs"
      assert dataset.description == "All POIs"
      assert dataset.geometry_type == "point"
      assert dataset.is_system == true
      assert dataset.tour_id == nil
    end

    test "create_system_dataset/1 with field_schema creates properly" do
      attrs = %{
        name: "Countries",
        geometry_type: "polygon",
        field_schema: [
          %{"name" => "code", "type" => "string"},
          %{"name" => "population", "type" => "integer"}
        ]
      }

      assert {:ok, %Dataset{} = dataset} = Datasets.create_system_dataset(attrs)
      assert length(dataset.field_schema) == 2
    end

    test "create_system_dataset/1 with invalid geometry_type returns error" do
      attrs = %{name: "Bad", geometry_type: "invalid"}
      assert {:error, %Ecto.Changeset{} = changeset} = Datasets.create_system_dataset(attrs)
      assert "is invalid" in errors_on(changeset).geometry_type
    end

    test "create_tour_dataset/2 creates a user dataset for a tour" do
      %{tour: tour} = create_tour()
      attrs = %{name: "My Favorite Places", geometry_type: "point"}

      assert {:ok, %Dataset{} = dataset} = Datasets.create_tour_dataset(tour.id, attrs)
      assert dataset.name == "My Favorite Places"
      assert dataset.is_system == false
      assert dataset.tour_id == tour.id
    end

    test "update_dataset/2 updates the dataset" do
      dataset = create_system_dataset(%{name: "Original"})
      assert {:ok, updated} = Datasets.update_dataset(dataset, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "delete_dataset/1 deletes the dataset" do
      dataset = create_system_dataset()
      assert {:ok, %Dataset{}} = Datasets.delete_dataset(dataset)
      assert_raise Ecto.NoResultsError, fn -> Datasets.get_dataset!(dataset.id) end
    end

    test "change_dataset/1 returns a changeset" do
      dataset = create_system_dataset()
      assert %Ecto.Changeset{} = Datasets.change_dataset(dataset)
    end
  end

  # ===========================================================================
  # Dataset Items Tests
  # ===========================================================================

  describe "dataset_items" do
    setup do
      dataset = create_system_dataset()
      %{dataset: dataset}
    end

    test "list_dataset_items/1 returns all items in a dataset", %{dataset: dataset} do
      {:ok, item1} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Petra",
          geometry: DatasetItem.point(35.4444, 30.3285),
          position: 1
        })

      {:ok, item2} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Wadi Rum",
          geometry: DatasetItem.point(35.4241, 29.5759),
          position: 2
        })

      items = Datasets.list_dataset_items(dataset.id)
      assert length(items) == 2
      assert Enum.map(items, & &1.id) == [item1.id, item2.id]
    end

    test "list_dataset_items/1 returns items ordered by position", %{dataset: dataset} do
      {:ok, _} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Second",
          position: 2
        })

      {:ok, _} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "First",
          position: 1
        })

      items = Datasets.list_dataset_items(dataset.id)
      assert Enum.map(items, & &1.name) == ["First", "Second"]
    end

    test "create_dataset_item/1 creates an item with geometry", %{dataset: dataset} do
      attrs = %{
        dataset_id: dataset.id,
        name: "Test POI",
        description: "A test point",
        geometry: DatasetItem.point(35.0, 30.0),
        properties: %{"rating" => 5, "category" => "landmark"}
      }

      assert {:ok, %DatasetItem{} = item} = Datasets.create_dataset_item(attrs)
      assert item.name == "Test POI"
      assert item.description == "A test point"
      assert item.geometry.coordinates == {35.0, 30.0}
      assert item.properties["rating"] == 5
    end

    test "create_dataset_item/1 with line geometry", %{dataset: dataset} do
      coords = [{35.0, 30.0}, {36.0, 31.0}, {37.0, 32.0}]

      attrs = %{
        dataset_id: dataset.id,
        name: "Scenic Route",
        geometry: DatasetItem.line(coords)
      }

      assert {:ok, %DatasetItem{} = item} = Datasets.create_dataset_item(attrs)
      assert %Geo.LineString{} = item.geometry
      assert length(item.geometry.coordinates) == 3
    end

    test "create_dataset_item/1 with polygon geometry", %{dataset: dataset} do
      coords = [{35.0, 30.0}, {36.0, 30.0}, {36.0, 31.0}, {35.0, 31.0}, {35.0, 30.0}]

      attrs = %{
        dataset_id: dataset.id,
        name: "Risk Zone",
        geometry: DatasetItem.polygon(coords)
      }

      assert {:ok, %DatasetItem{} = item} = Datasets.create_dataset_item(attrs)
      assert %Geo.Polygon{} = item.geometry
    end

    test "create_dataset_item/1 without name returns error", %{dataset: dataset} do
      attrs = %{dataset_id: dataset.id, name: nil}
      assert {:error, %Ecto.Changeset{} = changeset} = Datasets.create_dataset_item(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "get_dataset_item!/1 returns the item", %{dataset: dataset} do
      {:ok, item} =
        Datasets.create_dataset_item(%{dataset_id: dataset.id, name: "Test"})

      assert Datasets.get_dataset_item!(item.id) == item
    end

    test "update_dataset_item/2 updates the item", %{dataset: dataset} do
      {:ok, item} =
        Datasets.create_dataset_item(%{dataset_id: dataset.id, name: "Original"})

      assert {:ok, updated} = Datasets.update_dataset_item(item, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "delete_dataset_item/1 deletes the item", %{dataset: dataset} do
      {:ok, item} =
        Datasets.create_dataset_item(%{dataset_id: dataset.id, name: "Test"})

      assert {:ok, %DatasetItem{}} = Datasets.delete_dataset_item(item)
      assert_raise Ecto.NoResultsError, fn -> Datasets.get_dataset_item!(item.id) end
    end
  end

  # ===========================================================================
  # Tour Overrides Tests
  # ===========================================================================

  describe "tour_overrides" do
    setup do
      %{tour: tour} = create_tour()
      dataset = create_system_dataset()

      {:ok, item} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Petra",
          description: "Ancient city"
        })

      %{tour: tour, dataset: dataset, item: item}
    end

    test "get_tour_override/2 returns nil when no override exists", %{tour: tour, item: item} do
      assert Datasets.get_tour_override(tour.id, item.id) == nil
    end

    test "upsert_tour_override/3 creates a new override", %{tour: tour, item: item} do
      attrs = %{
        overrides: %{"description" => "My notes about Petra"},
        private_notes: "Visit in spring"
      }

      assert {:ok, %TourOverride{} = override} =
               Datasets.upsert_tour_override(tour.id, item.id, attrs)

      assert override.tour_id == tour.id
      assert override.dataset_item_id == item.id
      assert override.overrides["description"] == "My notes about Petra"
      assert override.private_notes == "Visit in spring"
      assert override.hidden == false
    end

    test "upsert_tour_override/3 updates an existing override", %{tour: tour, item: item} do
      # Create initial override
      {:ok, _} =
        Datasets.upsert_tour_override(tour.id, item.id, %{
          private_notes: "Original note"
        })

      # Update the override
      {:ok, updated} =
        Datasets.upsert_tour_override(tour.id, item.id, %{
          private_notes: "Updated note"
        })

      assert updated.private_notes == "Updated note"

      # Only one override should exist
      overrides = Datasets.list_tour_overrides(tour.id)
      assert length(overrides) == 1
    end

    test "upsert_tour_override/3 can hide an item", %{tour: tour, item: item} do
      {:ok, override} =
        Datasets.upsert_tour_override(tour.id, item.id, %{hidden: true})

      assert override.hidden == true
    end

    test "list_tour_overrides/1 returns all overrides for a tour", %{
      tour: tour,
      dataset: dataset,
      item: item
    } do
      {:ok, item2} =
        Datasets.create_dataset_item(%{dataset_id: dataset.id, name: "Wadi Rum"})

      {:ok, _} = Datasets.upsert_tour_override(tour.id, item.id, %{hidden: true})
      {:ok, _} = Datasets.upsert_tour_override(tour.id, item2.id, %{private_notes: "Nice"})

      overrides = Datasets.list_tour_overrides(tour.id)
      assert length(overrides) == 2
    end

    test "delete_tour_override/1 deletes the override", %{tour: tour, item: item} do
      {:ok, override} = Datasets.upsert_tour_override(tour.id, item.id, %{hidden: true})

      assert {:ok, %TourOverride{}} = Datasets.delete_tour_override(override)
      assert Datasets.get_tour_override(tour.id, item.id) == nil
    end
  end

  # ===========================================================================
  # Tour Additions Tests
  # ===========================================================================

  describe "tour_additions" do
    setup do
      %{tour: tour} = create_tour()
      dataset = create_system_dataset()
      %{tour: tour, dataset: dataset}
    end

    test "list_tour_additions/2 returns additions for a specific tour and dataset", %{
      tour: tour,
      dataset: dataset
    } do
      {:ok, addition} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "My Custom POI",
          geometry: DatasetItem.point(35.0, 30.0)
        })

      additions = Datasets.list_tour_additions(tour.id, dataset.id)
      assert length(additions) == 1
      assert hd(additions).id == addition.id
    end

    test "list_tour_additions/2 does not return other tour's additions", %{dataset: dataset} do
      %{tour: tour1} = create_tour()
      %{tour: tour2} = create_tour()

      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour1.id,
          dataset_id: dataset.id,
          name: "Tour 1 POI"
        })

      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour2.id,
          dataset_id: dataset.id,
          name: "Tour 2 POI"
        })

      additions = Datasets.list_tour_additions(tour1.id, dataset.id)
      assert length(additions) == 1
      assert hd(additions).name == "Tour 1 POI"
    end

    test "list_all_tour_additions/1 returns all additions for a tour", %{tour: tour} do
      dataset1 = create_system_dataset(%{name: "POIs"})
      dataset2 = create_system_dataset(%{name: "Routes"})

      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset1.id,
          name: "Addition 1"
        })

      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset2.id,
          name: "Addition 2"
        })

      additions = Datasets.list_all_tour_additions(tour.id)
      assert length(additions) == 2
    end

    test "create_tour_addition/1 creates an addition with geometry", %{
      tour: tour,
      dataset: dataset
    } do
      attrs = %{
        tour_id: tour.id,
        dataset_id: dataset.id,
        name: "My Secret Spot",
        description: "A hidden gem",
        geometry: DatasetItem.point(35.5, 30.5),
        properties: %{"type" => "viewpoint"},
        rating: 5
      }

      assert {:ok, %TourAddition{} = addition} = Datasets.create_tour_addition(attrs)
      assert addition.name == "My Secret Spot"
      assert addition.description == "A hidden gem"
      assert addition.geometry.coordinates == {35.5, 30.5}
      assert addition.properties["type"] == "viewpoint"
      assert addition.rating == 5
    end

    test "create_tour_addition/1 without name returns error", %{tour: tour, dataset: dataset} do
      attrs = %{tour_id: tour.id, dataset_id: dataset.id, name: nil}
      assert {:error, %Ecto.Changeset{} = changeset} = Datasets.create_tour_addition(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_tour_addition/1 validates rating range", %{tour: tour, dataset: dataset} do
      attrs = %{tour_id: tour.id, dataset_id: dataset.id, name: "Test", rating: 10}
      assert {:error, %Ecto.Changeset{} = changeset} = Datasets.create_tour_addition(attrs)
      assert "must be less than or equal to 5" in errors_on(changeset).rating
    end

    test "get_tour_addition!/1 returns the addition", %{tour: tour, dataset: dataset} do
      {:ok, addition} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "Test"
        })

      assert Datasets.get_tour_addition!(addition.id) == addition
    end

    test "update_tour_addition/2 updates the addition", %{tour: tour, dataset: dataset} do
      {:ok, addition} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "Original"
        })

      assert {:ok, updated} = Datasets.update_tour_addition(addition, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "delete_tour_addition/1 deletes the addition", %{tour: tour, dataset: dataset} do
      {:ok, addition} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "Test"
        })

      assert {:ok, %TourAddition{}} = Datasets.delete_tour_addition(addition)
      assert_raise Ecto.NoResultsError, fn -> Datasets.get_tour_addition!(addition.id) end
    end
  end

  # ===========================================================================
  # Combined Queries Tests
  # ===========================================================================

  describe "list_items_for_tour/2" do
    setup do
      %{tour: tour} = create_tour()
      dataset = create_system_dataset()

      # Create system items
      {:ok, item1} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Petra",
          description: "Ancient city",
          position: 1
        })

      {:ok, item2} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Wadi Rum",
          description: "Desert valley",
          position: 2
        })

      {:ok, item3} =
        Datasets.create_dataset_item(%{
          dataset_id: dataset.id,
          name: "Dead Sea",
          description: "Salt lake",
          position: 3
        })

      %{tour: tour, dataset: dataset, item1: item1, item2: item2, item3: item3}
    end

    test "returns all system items when no overrides", %{tour: tour, dataset: dataset} do
      items = Datasets.list_items_for_tour(dataset.id, tour.id)
      assert length(items) == 3
      assert Enum.all?(items, &(&1.source == :system))
    end

    test "excludes hidden items", %{tour: tour, dataset: dataset, item2: item2} do
      # Hide Wadi Rum
      {:ok, _} = Datasets.upsert_tour_override(tour.id, item2.id, %{hidden: true})

      items = Datasets.list_items_for_tour(dataset.id, tour.id)
      assert length(items) == 2
      names = Enum.map(items, & &1.item.name)
      assert "Petra" in names
      assert "Dead Sea" in names
      refute "Wadi Rum" in names
    end

    test "includes overrides in returned data", %{tour: tour, dataset: dataset, item1: item1} do
      # Add override to Petra
      {:ok, _} =
        Datasets.upsert_tour_override(tour.id, item1.id, %{
          overrides: %{"description" => "My notes"},
          private_notes: "Visit early"
        })

      items = Datasets.list_items_for_tour(dataset.id, tour.id)
      petra = Enum.find(items, &(&1.item.name == "Petra"))

      assert petra.overrides["description"] == "My notes"
      assert petra.private_notes == "Visit early"
    end

    test "includes user additions", %{tour: tour, dataset: dataset} do
      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "My Custom Spot",
          geometry: DatasetItem.point(35.0, 30.0)
        })

      items = Datasets.list_items_for_tour(dataset.id, tour.id)
      assert length(items) == 4

      user_items = Enum.filter(items, &(&1.source == :user))
      assert length(user_items) == 1
      assert hd(user_items).item.name == "My Custom Spot"
    end

    test "combines system items with overrides and user additions", %{
      tour: tour,
      dataset: dataset,
      item1: item1,
      item2: item2
    } do
      # Hide one item
      {:ok, _} = Datasets.upsert_tour_override(tour.id, item2.id, %{hidden: true})

      # Add override to another
      {:ok, _} =
        Datasets.upsert_tour_override(tour.id, item1.id, %{
          private_notes: "Favorite!"
        })

      # Add user item
      {:ok, _} =
        Datasets.create_tour_addition(%{
          tour_id: tour.id,
          dataset_id: dataset.id,
          name: "User POI"
        })

      items = Datasets.list_items_for_tour(dataset.id, tour.id)

      # 3 system items - 1 hidden + 1 user = 3 total
      assert length(items) == 3

      system_items = Enum.filter(items, &(&1.source == :system))
      user_items = Enum.filter(items, &(&1.source == :user))

      assert length(system_items) == 2
      assert length(user_items) == 1

      petra = Enum.find(items, &(&1.item.name == "Petra"))
      assert petra.private_notes == "Favorite!"
    end
  end
end
