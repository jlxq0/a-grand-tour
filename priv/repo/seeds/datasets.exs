# Seeds system datasets and imports data from _old/data folder
#
# Run with: mix run priv/repo/seeds/datasets.exs

alias GrandTour.Repo
alias GrandTour.Datasets
alias GrandTour.Datasets.Dataset
alias GrandTour.Datasets.DatasetItem

import Ecto.Query

# Helper to read and parse GeoJSON
defmodule SeedHelpers do
  def read_geojson(path) do
    case File.read(path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, _} -> nil
    end
  end

  def slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  def find_images(base_path, slug, max \\ 5) do
    1..max
    |> Enum.map(fn n -> "#{base_path}/#{slug}-#{n}.webp" end)
    |> Enum.filter(&File.exists?/1)
  end

  def find_images_in_folder(folder_path) do
    case File.ls(folder_path) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".webp"))
        |> Enum.sort()
        |> Enum.take(5)
        |> Enum.map(&Path.join(folder_path, &1))

      _ ->
        []
    end
  end

  def geometry_from_geojson(%{"type" => "Point", "coordinates" => [lng, lat]}) do
    %Geo.Point{coordinates: {lng, lat}, srid: 4326}
  end

  def geometry_from_geojson(%{"type" => "LineString", "coordinates" => coords}) do
    coordinates = Enum.map(coords, fn [lng, lat] -> {lng, lat} end)
    %Geo.LineString{coordinates: coordinates, srid: 4326}
  end

  def geometry_from_geojson(%{"type" => "Polygon", "coordinates" => [outer | _]}) do
    coordinates = Enum.map(outer, fn [lng, lat] -> {lng, lat} end)
    %Geo.Polygon{coordinates: [coordinates], srid: 4326}
  end

  def geometry_from_geojson(%{"type" => "MultiPolygon", "coordinates" => rings}) do
    # MultiPolygon coordinates need to stay as nested lists for PostGIS encoding
    coordinates =
      Enum.map(rings, fn ring_coords ->
        Enum.map(ring_coords, fn linear_ring ->
          Enum.map(linear_ring, fn [lng, lat] -> {lng, lat} end)
        end)
      end)

    %Geo.MultiPolygon{coordinates: coordinates, srid: 4326}
  end

  def geometry_from_geojson(_), do: nil
end

data_dir = Path.join(File.cwd!(), "_old/data")

IO.puts("\n=== Seeding System Datasets ===\n")

# ===========================================================================
# 1. Create System Datasets
# ===========================================================================

datasets_config = [
  %{
    name: "Points of Interest",
    description: "Notable landmarks, natural wonders, and cultural sites",
    geometry_type: "point",
    position: 1,
    field_schema: [
      %{"name" => "category", "type" => "string", "label" => "Category"},
      %{"name" => "countryCode", "type" => "string", "label" => "Country Code"},
      %{"name" => "rating", "type" => "integer", "label" => "Rating"}
    ]
  },
  %{
    name: "Scenic Routes",
    description: "Beautiful driving routes and roads",
    geometry_type: "line",
    position: 2,
    field_schema: [
      %{"name" => "countryCode", "type" => "string", "label" => "Country Code"},
      %{"name" => "rating", "type" => "integer", "label" => "Rating"}
    ]
  },
  %{
    name: "Ferries",
    description: "Vehicle ferry routes between ports",
    geometry_type: "line",
    position: 3,
    field_schema: [
      %{"name" => "operator", "type" => "string", "label" => "Operator"},
      %{"name" => "duration", "type" => "string", "label" => "Duration"},
      %{"name" => "cost", "type" => "string", "label" => "Cost"},
      %{"name" => "frequency", "type" => "string", "label" => "Frequency"}
    ]
  },
  %{
    name: "Shipping Routes",
    description: "Container and RoRo shipping routes for vehicle transport",
    geometry_type: "line",
    position: 4,
    field_schema: [
      %{"name" => "operator", "type" => "string", "label" => "Operator"},
      %{"name" => "duration", "type" => "string", "label" => "Duration"}
    ]
  },
  %{
    name: "Risk Regions",
    description: "Areas with travel advisories or safety concerns",
    geometry_type: "polygon",
    position: 5,
    field_schema: [
      %{"name" => "risk", "type" => "string", "label" => "Risk Level"},
      %{"name" => "note", "type" => "text", "label" => "Notes"}
    ]
  },
  %{
    name: "Safe Corridors",
    description: "Recommended routes through challenging regions",
    geometry_type: "line",
    position: 6,
    field_schema: [
      %{"name" => "note", "type" => "text", "label" => "Notes"}
    ]
  }
]

# Delete existing system datasets and recreate
Repo.delete_all(from(d in Dataset, where: d.is_system == true))

datasets =
  Enum.map(datasets_config, fn config ->
    {:ok, dataset} = Datasets.create_system_dataset(config)
    IO.puts("Created dataset: #{dataset.name}")
    {config.name, dataset}
  end)
  |> Map.new()

IO.puts("\n=== Importing Data ===\n")

# ===========================================================================
# 2. Import POIs
# ===========================================================================

pois_dataset = datasets["Points of Interest"]
pois_dir = Path.join(data_dir, "pois")
pois_images_dir = Path.join(pois_dir, "images")

poi_files =
  case File.ls(pois_dir) do
    {:ok, files} -> Enum.filter(files, &String.ends_with?(&1, ".geojson"))
    _ -> []
  end

poi_count =
  Enum.reduce(poi_files, 0, fn file, acc ->
    path = Path.join(pois_dir, file)
    country_code = String.replace(file, ".geojson", "")

    case SeedHelpers.read_geojson(path) do
      %{"features" => features} ->
        Enum.each(features, fn feature ->
          props = feature["properties"] || %{}
          name = props["name"]
          slug = SeedHelpers.slugify(name)

          # Find images for this POI
          images_path = Path.join([pois_images_dir, country_code])
          images = SeedHelpers.find_images(images_path, slug)

          # Convert to relative paths for storage
          relative_images =
            Enum.map(images, fn img ->
              String.replace(img, File.cwd!() <> "/", "")
            end)

          Datasets.create_dataset_item(%{
            dataset_id: pois_dataset.id,
            name: name,
            description: props["description"],
            geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
            rating: props["rating"],
            images: relative_images,
            properties: %{
              "category" => props["category"],
              "countryCode" => props["countryCode"] || country_code |> String.upcase(),
              "country" => props["country"]
            }
          })
        end)

        acc + length(features)

      _ ->
        acc
    end
  end)

IO.puts("Imported #{poi_count} POIs")

# ===========================================================================
# 3. Import Scenic Routes
# ===========================================================================

scenic_dataset = datasets["Scenic Routes"]
scenic_dir = Path.join(data_dir, "scenic-routes")
scenic_images_dir = Path.join(scenic_dir, "images")

scenic_files =
  case File.ls(scenic_dir) do
    {:ok, files} -> Enum.filter(files, &String.ends_with?(&1, ".geojson"))
    _ -> []
  end

scenic_count =
  Enum.reduce(scenic_files, 0, fn file, acc ->
    path = Path.join(scenic_dir, file)
    slug = String.replace(file, ".geojson", "")

    case SeedHelpers.read_geojson(path) do
      %{"properties" => props, "geometry" => geometry} ->
        # Single Feature (not FeatureCollection)
        images_folder = Path.join(scenic_images_dir, slug)
        images = SeedHelpers.find_images_in_folder(images_folder)

        relative_images =
          Enum.map(images, fn img ->
            String.replace(img, File.cwd!() <> "/", "")
          end)

        Datasets.create_dataset_item(%{
          dataset_id: scenic_dataset.id,
          name: props["name"],
          description: props["description"],
          geometry: SeedHelpers.geometry_from_geojson(geometry),
          rating: props["rating"],
          images: relative_images,
          properties: %{
            "countryCode" => props["countryCode"],
            "country" => props["country"]
          }
        })

        acc + 1

      %{"features" => features} ->
        # FeatureCollection
        Enum.each(features, fn feature ->
          props = feature["properties"] || %{}

          Datasets.create_dataset_item(%{
            dataset_id: scenic_dataset.id,
            name: props["name"],
            description: props["description"],
            geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
            rating: props["rating"],
            properties: %{
              "countryCode" => props["countryCode"],
              "country" => props["country"]
            }
          })
        end)

        acc + length(features)

      _ ->
        acc
    end
  end)

IO.puts("Imported #{scenic_count} scenic routes")

# ===========================================================================
# 4. Import Ferries
# ===========================================================================

ferries_dataset = datasets["Ferries"]
ferries_path = Path.join(data_dir, "ferries.geojson")
ferries_images_dir = Path.join(data_dir, "ferries/images")

ferry_count =
  case SeedHelpers.read_geojson(ferries_path) do
    %{"features" => features} ->
      Enum.each(features, fn feature ->
        props = feature["properties"] || %{}
        name = props["name"]
        slug = SeedHelpers.slugify(name)

        # Check for image
        image_path = Path.join(ferries_images_dir, "#{slug}.webp")

        images =
          if File.exists?(image_path) do
            [String.replace(image_path, File.cwd!() <> "/", "")]
          else
            []
          end

        Datasets.create_dataset_item(%{
          dataset_id: ferries_dataset.id,
          name: name,
          description: props["notes"],
          geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
          images: images,
          properties: %{
            "operator" => props["operator"],
            "duration" => props["duration"],
            "cost" => props["cost"],
            "frequency" => props["frequency"],
            "legs" => props["legs"]
          }
        })
      end)

      length(features)

    _ ->
      0
  end

IO.puts("Imported #{ferry_count} ferries")

# ===========================================================================
# 5. Import Shipping Routes
# ===========================================================================

shipping_dataset = datasets["Shipping Routes"]
shipping_dir = Path.join(data_dir, "shipping")
shipping_images_dir = Path.join(shipping_dir, "images")

shipping_files =
  case File.ls(shipping_dir) do
    {:ok, files} -> Enum.filter(files, &String.ends_with?(&1, ".geojson"))
    _ -> []
  end

shipping_count =
  Enum.reduce(shipping_files, 0, fn file, acc ->
    path = Path.join(shipping_dir, file)
    slug = String.replace(file, ".geojson", "")

    case SeedHelpers.read_geojson(path) do
      %{"features" => features} ->
        Enum.each(features, fn feature ->
          props = feature["properties"] || %{}
          name = props["name"] || slug

          # Check for image folder
          images_folder = Path.join(shipping_images_dir, slug)
          images = SeedHelpers.find_images_in_folder(images_folder)

          relative_images =
            Enum.map(images, fn img ->
              String.replace(img, File.cwd!() <> "/", "")
            end)

          Datasets.create_dataset_item(%{
            dataset_id: shipping_dataset.id,
            name: name,
            geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
            images: relative_images,
            properties: %{
              "color" => props["color"]
            }
          })
        end)

        acc + length(features)

      _ ->
        acc
    end
  end)

IO.puts("Imported #{shipping_count} shipping routes")

# ===========================================================================
# 6. Import Risk Regions
# ===========================================================================

risk_dataset = datasets["Risk Regions"]
risk_path = Path.join(data_dir, "risk-regions.geojson")

risk_count =
  case SeedHelpers.read_geojson(risk_path) do
    %{"features" => features} ->
      Enum.each(features, fn feature ->
        props = feature["properties"] || %{}

        Datasets.create_dataset_item(%{
          dataset_id: risk_dataset.id,
          name: props["name"],
          description: props["note"],
          geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
          properties: %{
            "risk" => props["risk"]
          }
        })
      end)

      length(features)

    _ ->
      0
  end

IO.puts("Imported #{risk_count} risk regions")

# ===========================================================================
# 7. Import Safe Corridors
# ===========================================================================

corridors_dataset = datasets["Safe Corridors"]
corridors_dir = Path.join(data_dir, "safe-corridors")

corridor_files =
  case File.ls(corridors_dir) do
    {:ok, files} -> Enum.filter(files, &String.ends_with?(&1, ".geojson"))
    _ -> []
  end

corridor_count =
  Enum.reduce(corridor_files, 0, fn file, acc ->
    path = Path.join(corridors_dir, file)
    name = file |> String.replace(".geojson", "") |> String.replace("-", " ") |> String.capitalize()

    case SeedHelpers.read_geojson(path) do
      %{"features" => features} ->
        Enum.each(features, fn feature ->
          props = feature["properties"] || %{}

          Datasets.create_dataset_item(%{
            dataset_id: corridors_dataset.id,
            name: props["name"] || name,
            description: props["note"],
            geometry: SeedHelpers.geometry_from_geojson(feature["geometry"]),
            properties: %{}
          })
        end)

        acc + length(features)

      %{"geometry" => geometry} = data when is_map(geometry) ->
        # Single Feature
        props = data["properties"] || %{}

        Datasets.create_dataset_item(%{
          dataset_id: corridors_dataset.id,
          name: props["name"] || name,
          description: props["note"],
          geometry: SeedHelpers.geometry_from_geojson(geometry),
          properties: %{}
        })

        acc + 1

      _ ->
        acc
    end
  end)

IO.puts("Imported #{corridor_count} safe corridors")

IO.puts("\n=== Seeding Complete ===\n")

# Summary
total_items =
  Repo.aggregate(from(i in DatasetItem), :count, :id)

IO.puts("Total dataset items: #{total_items}")
