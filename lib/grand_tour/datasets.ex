defmodule GrandTour.Datasets do
  @moduledoc """
  The Datasets context.

  Manages datasets (collections of geo-data), items within datasets,
  and user customizations (overrides and additions) to system datasets.
  """

  import Ecto.Query, warn: false
  alias GrandTour.Repo

  alias GrandTour.Datasets.Dataset
  alias GrandTour.Datasets.DatasetItem
  alias GrandTour.Datasets.TourOverride
  alias GrandTour.Datasets.TourAddition

  # ===========================================================================
  # Datasets
  # ===========================================================================

  @doc """
  Returns all system datasets.
  """
  def list_system_datasets do
    Dataset
    |> where([d], d.is_system == true)
    |> order_by([d], d.position)
    |> Repo.all()
  end

  @doc """
  Returns all datasets for a tour (user-created datasets only).
  """
  def list_tour_datasets(tour_id) do
    Dataset
    |> where([d], d.tour_id == ^tour_id)
    |> order_by([d], d.position)
    |> Repo.all()
  end

  @doc """
  Returns all datasets available for a tour: system datasets + user datasets.
  """
  def list_all_datasets(tour_id) do
    Dataset
    |> where([d], d.is_system == true or d.tour_id == ^tour_id)
    |> order_by([d], desc: d.is_system, asc: d.position)
    |> Repo.all()
  end

  @doc """
  Gets a single dataset.
  Raises `Ecto.NoResultsError` if the Dataset does not exist.
  """
  def get_dataset!(id), do: Repo.get!(Dataset, id)

  @doc """
  Creates a system dataset.
  """
  def create_system_dataset(attrs \\ %{}) do
    %Dataset{}
    |> Dataset.system_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a user dataset for a specific tour.
  """
  def create_tour_dataset(tour_id, attrs \\ %{}) do
    %Dataset{}
    |> Dataset.user_changeset(attrs, tour_id)
    |> Repo.insert()
  end

  @doc """
  Updates a dataset.
  """
  def update_dataset(%Dataset{} = dataset, attrs) do
    dataset
    |> Dataset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dataset.
  """
  def delete_dataset(%Dataset{} = dataset) do
    Repo.delete(dataset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dataset changes.
  """
  def change_dataset(%Dataset{} = dataset, attrs \\ %{}) do
    Dataset.changeset(dataset, attrs)
  end

  # ===========================================================================
  # Dataset Items
  # ===========================================================================

  @doc """
  Returns all items in a dataset.
  """
  def list_dataset_items(dataset_id) do
    DatasetItem
    |> where([i], i.dataset_id == ^dataset_id)
    |> order_by([i], i.position)
    |> Repo.all()
  end

  @doc """
  Returns items in a dataset within a bounding box.
  Used for loading items visible in the current map viewport.

  bbox should be a map with :min_lng, :min_lat, :max_lng, :max_lat
  """
  def list_dataset_items_in_bbox(dataset_id, %{
        min_lng: min_lng,
        min_lat: min_lat,
        max_lng: max_lng,
        max_lat: max_lat
      }) do
    envelope = "ST_MakeEnvelope(#{min_lng}, #{min_lat}, #{max_lng}, #{max_lat}, 4326)"

    DatasetItem
    |> where([i], i.dataset_id == ^dataset_id)
    |> where([i], fragment("? && ?", i.bbox, fragment(^envelope)))
    |> order_by([i], i.position)
    |> Repo.all()
  end

  @doc """
  Gets a single dataset item.
  """
  def get_dataset_item!(id), do: Repo.get!(DatasetItem, id)

  @doc """
  Creates a dataset item.
  """
  def create_dataset_item(attrs \\ %{}) do
    %DatasetItem{}
    |> DatasetItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a dataset item.
  """
  def update_dataset_item(%DatasetItem{} = item, attrs) do
    item
    |> DatasetItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dataset item.
  """
  def delete_dataset_item(%DatasetItem{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dataset item changes.
  """
  def change_dataset_item(%DatasetItem{} = item, attrs \\ %{}) do
    DatasetItem.changeset(item, attrs)
  end

  # ===========================================================================
  # Tour Overrides (user modifications to system items)
  # ===========================================================================

  @doc """
  Gets a user's override for a specific system item, if it exists.
  """
  def get_tour_override(tour_id, dataset_item_id) do
    TourOverride
    |> where([o], o.tour_id == ^tour_id and o.dataset_item_id == ^dataset_item_id)
    |> Repo.one()
  end

  @doc """
  Creates or updates a user's override for a system item.
  """
  def upsert_tour_override(tour_id, dataset_item_id, attrs) do
    case get_tour_override(tour_id, dataset_item_id) do
      nil ->
        %TourOverride{}
        |> TourOverride.changeset(
          Map.merge(attrs, %{tour_id: tour_id, dataset_item_id: dataset_item_id})
        )
        |> Repo.insert()

      override ->
        override
        |> TourOverride.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Deletes a user's override (reverts to system defaults).
  """
  def delete_tour_override(%TourOverride{} = override) do
    Repo.delete(override)
  end

  @doc """
  Returns all overrides for a tour.
  """
  def list_tour_overrides(tour_id) do
    TourOverride
    |> where([o], o.tour_id == ^tour_id)
    |> Repo.all()
  end

  # ===========================================================================
  # Tour Additions (user items added to system datasets)
  # ===========================================================================

  @doc """
  Returns all user additions to a dataset for a specific tour.
  """
  def list_tour_additions(tour_id, dataset_id) do
    TourAddition
    |> where([a], a.tour_id == ^tour_id and a.dataset_id == ^dataset_id)
    |> order_by([a], a.position)
    |> Repo.all()
  end

  @doc """
  Returns all user additions for a tour across all datasets.
  """
  def list_all_tour_additions(tour_id) do
    TourAddition
    |> where([a], a.tour_id == ^tour_id)
    |> order_by([a], a.position)
    |> Repo.all()
  end

  @doc """
  Gets a single tour addition.
  """
  def get_tour_addition!(id), do: Repo.get!(TourAddition, id)

  @doc """
  Creates a tour addition (user item in a system dataset).
  """
  def create_tour_addition(attrs \\ %{}) do
    %TourAddition{}
    |> TourAddition.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tour addition.
  """
  def update_tour_addition(%TourAddition{} = addition, attrs) do
    addition
    |> TourAddition.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tour addition.
  """
  def delete_tour_addition(%TourAddition{} = addition) do
    Repo.delete(addition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tour addition changes.
  """
  def change_tour_addition(%TourAddition{} = addition, attrs \\ %{}) do
    TourAddition.changeset(addition, attrs)
  end

  # ===========================================================================
  # Combined Queries (system items + user items with overrides)
  # ===========================================================================

  @doc """
  Returns all items for a dataset as visible to a specific tour.
  This includes:
  - System items (with user overrides applied, excluding hidden items)
  - User additions to the dataset

  Returns a list of maps with merged data.
  """
  def list_items_for_tour(dataset_id, tour_id) do
    # Get system items
    system_items = list_dataset_items(dataset_id)

    # Get overrides for this tour (indexed by item id)
    overrides =
      list_tour_overrides(tour_id)
      |> Enum.filter(fn o ->
        Enum.any?(system_items, &(&1.id == o.dataset_item_id))
      end)
      |> Map.new(fn o -> {o.dataset_item_id, o} end)

    # Apply overrides and filter hidden
    visible_system_items =
      system_items
      |> Enum.reject(fn item ->
        case Map.get(overrides, item.id) do
          %{hidden: true} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn item ->
        case Map.get(overrides, item.id) do
          nil ->
            %{item: item, overrides: %{}, source: :system}

          override ->
            %{
              item: item,
              overrides: override.overrides,
              private_notes: override.private_notes,
              source: :system
            }
        end
      end)

    # Get user additions
    user_additions =
      list_tour_additions(tour_id, dataset_id)
      |> Enum.map(fn addition ->
        %{item: addition, overrides: %{}, source: :user}
      end)

    # Combine and return
    visible_system_items ++ user_additions
  end
end
