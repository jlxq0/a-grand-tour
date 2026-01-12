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
  alias GrandTour.Datasets.UserDatasetPreference

  # Default view configurations per dataset type (by slug)
  @dataset_defaults %{
    "pois" => %{
      "view_type" => "card",
      "visible_fields" => ["name", "description", "rating", "country_code", "images"],
      "card_style" => "image_overlay",
      "sort_field" => "name",
      "sort_direction" => "asc"
    },
    "countries" => %{
      "view_type" => "card",
      "visible_fields" => ["name", "flag_emoji", "continent", "safety_rating", "driving_side"],
      "card_style" => "metadata",
      "sort_field" => "name",
      "sort_direction" => "asc"
    },
    "scenic-routes" => %{
      "view_type" => "card",
      "visible_fields" => [
        "name",
        "description",
        "rating",
        "country_code",
        "distance_km",
        "images"
      ],
      "card_style" => "image_overlay",
      "sort_field" => "name",
      "sort_direction" => "asc"
    },
    "ferries" => %{
      "view_type" => "table",
      "visible_fields" => ["name", "from_port", "to_port", "operator", "duration", "countries"],
      "sort_field" => "name",
      "sort_direction" => "asc"
    },
    "shipping" => %{
      "view_type" => "table",
      "visible_fields" => ["name", "from_port", "to_port", "company", "route_type"],
      "sort_field" => "name",
      "sort_direction" => "asc"
    },
    "risk-regions" => %{
      "view_type" => "table",
      "visible_fields" => ["name", "risk_level", "reason", "countries"],
      "sort_field" => "name",
      "sort_direction" => "asc"
    }
  }

  @default_preferences %{
    "view_type" => "list",
    "visible_fields" => ["name", "description", "rating"],
    "sort_field" => "name",
    "sort_direction" => "asc",
    "default_filter" => nil
  }

  # Map dataset names to slugs for default preferences lookup
  @name_to_slug %{
    "Points of Interest" => "pois",
    "Countries" => "countries",
    "Scenic Routes" => "scenic-routes",
    "Ferries" => "ferries",
    "Shipping" => "shipping",
    "Risk Regions" => "risk-regions"
  }

  @doc """
  Derives a slug from a dataset name for preferences lookup.
  """
  def dataset_name_to_slug(name) when is_binary(name) do
    Map.get(@name_to_slug, name, name |> String.downcase() |> String.replace(~r/\s+/, "-"))
  end

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

  # ===========================================================================
  # User Dataset Preferences
  # ===========================================================================

  @doc """
  Returns the default preferences for a dataset based on its slug.
  Falls back to generic defaults if slug not found.
  """
  def get_default_preferences(dataset_slug) when is_binary(dataset_slug) do
    Map.get(@dataset_defaults, dataset_slug, @default_preferences)
  end

  def get_default_preferences(_), do: @default_preferences

  @doc """
  Gets a user's preferences for a dataset.
  Returns merged preferences (user overrides on top of defaults).
  """
  def get_user_preferences(user_id, dataset_id) when not is_nil(user_id) do
    dataset = get_dataset!(dataset_id)
    defaults = get_default_preferences(dataset_name_to_slug(dataset.name))

    case Repo.get_by(UserDatasetPreference, user_id: user_id, dataset_id: dataset_id) do
      nil ->
        defaults

      %{preferences: prefs} ->
        Map.merge(defaults, prefs)
    end
  end

  def get_user_preferences(nil, dataset_id) do
    dataset = get_dataset!(dataset_id)
    get_default_preferences(dataset_name_to_slug(dataset.name))
  end

  @doc """
  Updates (upserts) a user's preferences for a dataset.
  """
  def update_user_preferences(user_id, dataset_id, attrs) do
    case Repo.get_by(UserDatasetPreference, user_id: user_id, dataset_id: dataset_id) do
      nil ->
        %UserDatasetPreference{}
        |> UserDatasetPreference.changeset(%{
          user_id: user_id,
          dataset_id: dataset_id,
          preferences: attrs
        })
        |> Repo.insert()

      existing ->
        merged = Map.merge(existing.preferences, attrs)

        existing
        |> UserDatasetPreference.changeset(%{preferences: merged})
        |> Repo.update()
    end
  end

  @doc """
  Resets a user's preferences for a dataset to defaults.
  """
  def reset_user_preferences(user_id, dataset_id) do
    case Repo.get_by(UserDatasetPreference, user_id: user_id, dataset_id: dataset_id) do
      nil -> :ok
      existing -> Repo.delete(existing)
    end
  end

  # ===========================================================================
  # Paginated Dataset Items Query
  # ===========================================================================

  @doc """
  Returns paginated dataset items with sorting and filtering.

  ## Options
    - `:limit` - max items to return (default: 50, max: 100)
    - `:offset` - offset for pagination (default: 0)
    - `:sort_field` - field to sort by (default: "name")
    - `:sort_direction` - "asc" or "desc" (default: "asc")
    - `:filter` - text to filter by (searches name and description)
  """
  def list_dataset_items_paginated(dataset_id, opts \\ []) do
    limit = min(Keyword.get(opts, :limit, 50), 100)
    offset = Keyword.get(opts, :offset, 0)
    sort_field = Keyword.get(opts, :sort_field, "name")
    sort_direction = Keyword.get(opts, :sort_direction, "asc")
    filter = Keyword.get(opts, :filter)
    filters = Keyword.get(opts, :filters, [])

    query =
      DatasetItem
      |> where([i], i.dataset_id == ^dataset_id)
      |> apply_filter(filter)
      |> apply_filters(filters)
      |> apply_sort(sort_field, sort_direction)
      |> limit(^limit)
      |> offset(^offset)

    Repo.all(query)
  end

  @doc """
  Returns the total count of items in a dataset, with optional filter.
  """
  def count_dataset_items(dataset_id, filter \\ nil, filters \\ []) do
    DatasetItem
    |> where([i], i.dataset_id == ^dataset_id)
    |> apply_filter(filter)
    |> apply_filters(filters)
    |> Repo.aggregate(:count)
  end

  defp apply_filter(query, nil), do: query
  defp apply_filter(query, ""), do: query

  defp apply_filter(query, filter) when is_binary(filter) do
    filter_term = "%#{filter}%"

    query
    |> where(
      [i],
      ilike(i.name, ^filter_term) or ilike(i.description, ^filter_term)
    )
  end

  # Apply structured filter conditions from filter builder
  defp apply_filters(query, []), do: query

  defp apply_filters(query, filters) when is_list(filters) do
    Enum.reduce(filters, query, fn filter, q ->
      apply_single_filter(q, filter)
    end)
  end

  defp apply_single_filter(query, %{field: field, op: op, value: value}) do
    apply_single_filter(query, %{"field" => field, "op" => op, "value" => value})
  end

  defp apply_single_filter(query, %{"field" => field, "op" => op, "value" => value}) do
    # Handle fields that might be in properties JSONB column
    case field do
      "name" -> apply_field_filter(query, :name, op, value)
      "description" -> apply_field_filter(query, :description, op, value)
      "rating" -> apply_field_filter(query, :rating, op, value)
      # Other fields are stored in the properties JSONB column
      _ -> apply_jsonb_filter(query, field, op, value)
    end
  end

  defp apply_field_filter(query, field_atom, "equals", value) do
    where(query, [i], field(i, ^field_atom) == ^value)
  end

  defp apply_field_filter(query, field_atom, "contains", value) do
    term = "%#{value}%"
    where(query, [i], ilike(field(i, ^field_atom), ^term))
  end

  defp apply_field_filter(query, field_atom, "starts_with", value) do
    term = "#{value}%"
    where(query, [i], ilike(field(i, ^field_atom), ^term))
  end

  defp apply_field_filter(query, field_atom, "ends_with", value) do
    term = "%#{value}"
    where(query, [i], ilike(field(i, ^field_atom), ^term))
  end

  defp apply_field_filter(query, field_atom, "greater_than", value) do
    # For numeric fields like rating, convert value to number
    case parse_number(value) do
      {:ok, num} -> where(query, [i], field(i, ^field_atom) > ^num)
      :error -> where(query, [i], field(i, ^field_atom) > ^value)
    end
  end

  defp apply_field_filter(query, field_atom, "less_than", value) do
    # For numeric fields like rating, convert value to number
    case parse_number(value) do
      {:ok, num} -> where(query, [i], field(i, ^field_atom) < ^num)
      :error -> where(query, [i], field(i, ^field_atom) < ^value)
    end
  end

  defp apply_field_filter(query, _field_atom, _op, _value), do: query

  # JSONB filters for properties stored in the properties column
  defp apply_jsonb_filter(query, field, "equals", value) do
    where(query, [i], fragment("properties->>? = ?", ^field, ^value))
  end

  defp apply_jsonb_filter(query, field, "contains", value) do
    where(query, [i], fragment("properties->>? ILIKE ?", ^field, ^"%#{value}%"))
  end

  defp apply_jsonb_filter(query, field, "starts_with", value) do
    where(query, [i], fragment("properties->>? ILIKE ?", ^field, ^"#{value}%"))
  end

  defp apply_jsonb_filter(query, field, "ends_with", value) do
    where(query, [i], fragment("properties->>? ILIKE ?", ^field, ^"%#{value}"))
  end

  defp apply_jsonb_filter(query, field, "greater_than", value) do
    where(query, [i], fragment("(properties->>?)::float > ?", ^field, ^String.to_float(value)))
  rescue
    _ -> query
  end

  defp apply_jsonb_filter(query, field, "less_than", value) do
    where(query, [i], fragment("(properties->>?)::float < ?", ^field, ^String.to_float(value)))
  rescue
    _ -> query
  end

  defp apply_jsonb_filter(query, _field, _op, _value), do: query

  defp apply_sort(query, field, direction) do
    # Only allow sorting by known fields for security
    field_atom = safe_sort_field(field)
    dir_atom = if direction == "desc", do: :desc, else: :asc

    order_by(query, [i], [{^dir_atom, field(i, ^field_atom)}])
  end

  defp safe_sort_field("name"), do: :name
  defp safe_sort_field("rating"), do: :rating
  defp safe_sort_field("position"), do: :position
  defp safe_sort_field("inserted_at"), do: :inserted_at
  defp safe_sort_field("updated_at"), do: :updated_at
  defp safe_sort_field(_), do: :name

  # Try to parse a string as a number (integer or float)
  defp parse_number(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} ->
        {:ok, int}

      _ ->
        case Float.parse(value) do
          {float, ""} -> {:ok, float}
          _ -> :error
        end
    end
  end

  defp parse_number(value) when is_number(value), do: {:ok, value}
  defp parse_number(_), do: :error

  # ===========================================================================
  # GeoJSON Export for Map Display
  # ===========================================================================

  @doc """
  Returns all items from a dataset as GeoJSON FeatureCollection.
  Optimized for map display - only includes necessary properties.
  """
  def get_dataset_geojson(dataset_name) when is_binary(dataset_name) do
    dataset = Repo.get_by(Dataset, name: dataset_name)

    if dataset do
      get_dataset_geojson_by_id(dataset.id)
    else
      empty_geojson()
    end
  end

  @doc """
  Returns all items from a dataset by ID as GeoJSON FeatureCollection.
  """
  def get_dataset_geojson_by_id(dataset_id) do
    items =
      DatasetItem
      |> where([i], i.dataset_id == ^dataset_id)
      |> where([i], not is_nil(i.geometry))
      |> select([i], %{
        id: i.id,
        name: i.name,
        rating: i.rating,
        geometry: i.geometry,
        properties: i.properties
      })
      |> Repo.all()

    features =
      Enum.map(items, fn item ->
        %{
          "type" => "Feature",
          "id" => item.id,
          "geometry" => geo_to_geojson(item.geometry),
          "properties" =>
            Map.merge(
              %{
                "id" => item.id,
                "name" => item.name,
                "rating" => item.rating
              },
              item.properties || %{}
            )
        }
      end)

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  @doc """
  Returns all map layer data as a map suitable for the map hook.
  Fetches all datasets efficiently in parallel.
  """
  def get_all_map_layers do
    datasets = list_system_datasets()
    dataset_map = Map.new(datasets, fn d -> {dataset_name_to_slug(d.name), d.id} end)

    # Fetch all datasets in parallel using Task.async_stream
    tasks = [
      {"pois", Map.get(dataset_map, "pois")},
      {"scenic_routes", Map.get(dataset_map, "scenic-routes")},
      {"ferries", Map.get(dataset_map, "ferries")},
      {"shipping", Map.get(dataset_map, "shipping-routes")},
      {"risk_regions", Map.get(dataset_map, "risk-regions")}
    ]

    tasks
    |> Task.async_stream(
      fn {key, dataset_id} ->
        if dataset_id do
          {key, get_dataset_geojson_by_id(dataset_id)}
        else
          {key, empty_geojson()}
        end
      end,
      timeout: :infinity,
      max_concurrency: 6
    )
    |> Enum.reduce(%{}, fn {:ok, {key, geojson}}, acc ->
      Map.put(acc, key, geojson)
    end)
  end

  defp empty_geojson do
    %{"type" => "FeatureCollection", "features" => []}
  end

  defp geo_to_geojson(nil), do: nil

  defp geo_to_geojson(%Geo.Point{coordinates: {lng, lat}}) do
    %{"type" => "Point", "coordinates" => [lng, lat]}
  end

  defp geo_to_geojson(%Geo.LineString{coordinates: coords}) do
    %{
      "type" => "LineString",
      "coordinates" => Enum.map(coords, fn {lng, lat} -> [lng, lat] end)
    }
  end

  defp geo_to_geojson(%Geo.Polygon{coordinates: rings}) do
    %{
      "type" => "Polygon",
      "coordinates" =>
        Enum.map(rings, fn ring ->
          Enum.map(ring, fn {lng, lat} -> [lng, lat] end)
        end)
    }
  end

  defp geo_to_geojson(%Geo.MultiPoint{coordinates: coords}) do
    %{
      "type" => "MultiPoint",
      "coordinates" => Enum.map(coords, fn {lng, lat} -> [lng, lat] end)
    }
  end

  defp geo_to_geojson(%Geo.MultiLineString{coordinates: lines}) do
    %{
      "type" => "MultiLineString",
      "coordinates" =>
        Enum.map(lines, fn line ->
          Enum.map(line, fn {lng, lat} -> [lng, lat] end)
        end)
    }
  end

  defp geo_to_geojson(%Geo.MultiPolygon{coordinates: polygons}) do
    %{
      "type" => "MultiPolygon",
      "coordinates" =>
        Enum.map(polygons, fn polygon ->
          Enum.map(polygon, fn ring ->
            Enum.map(ring, fn {lng, lat} -> [lng, lat] end)
          end)
        end)
    }
  end

  defp geo_to_geojson(_), do: nil
end
