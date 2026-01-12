# Seeds Countries dataset from Natural Earth data
#
# Run with: mix run priv/repo/seeds/countries.exs

alias GrandTour.Repo
alias GrandTour.Datasets
alias GrandTour.Datasets.Dataset
alias GrandTour.Datasets.DatasetItem

import Ecto.Query

IO.puts("\n=== Seeding Countries Dataset ===\n")

# Helper to read and parse GeoJSON
defmodule CountryHelpers do
  def read_geojson(path) do
    case File.read(path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, _} -> nil
    end
  end

  def geometry_from_geojson(%{"type" => "Polygon", "coordinates" => [outer | _]}) do
    coordinates = Enum.map(outer, fn [lng, lat] -> {lng, lat} end)
    %Geo.Polygon{coordinates: [coordinates], srid: 4326}
  end

  def geometry_from_geojson(%{"type" => "MultiPolygon", "coordinates" => rings}) do
    coordinates =
      Enum.map(rings, fn ring_coords ->
        Enum.map(ring_coords, fn linear_ring ->
          Enum.map(linear_ring, fn [lng, lat] -> {lng, lat} end)
        end)
      end)

    %Geo.MultiPolygon{coordinates: coordinates, srid: 4326}
  end

  def geometry_from_geojson(_), do: nil

  # Flag emoji from ISO 2-letter code
  def flag_emoji(nil), do: ""
  def flag_emoji(code) when is_binary(code) and byte_size(code) == 2 do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - ?A + 0x1F1E6))
    |> List.to_string()
  end
  def flag_emoji(_), do: ""

  # Left-hand drive countries
  @left_hand_countries MapSet.new([
    "AU", "BD", "BN", "BT", "BW", "CY", "FJ", "GB", "GY", "HK", "ID", "IE", "IN",
    "JM", "JP", "KE", "LK", "MO", "MT", "MU", "MW", "MY", "MZ", "NA", "NP", "NZ",
    "PK", "SG", "SR", "SZ", "TH", "TT", "TZ", "UG", "ZA", "ZM", "ZW"
  ])

  def driving_side(iso_code) do
    if MapSet.member?(@left_hand_countries, iso_code), do: "left", else: "right"
  end
end

# Check if Countries dataset exists
existing = Repo.one(from d in Dataset, where: d.name == "Countries" and d.is_system == true)

countries_dataset = if existing do
  IO.puts("Countries dataset exists, deleting existing items...")
  Repo.delete_all(from i in DatasetItem, where: i.dataset_id == ^existing.id)
  existing
else
  IO.puts("Creating Countries dataset...")
  {:ok, dataset} = Datasets.create_system_dataset(%{
    name: "Countries",
    description: "World countries with travel information",
    geometry_type: "polygon",
    position: 6,
    field_schema: [
      %{"name" => "continent", "type" => "string", "label" => "Continent"},
      %{"name" => "subregion", "type" => "string", "label" => "Subregion"},
      %{"name" => "flagEmoji", "type" => "string", "label" => "Flag"},
      %{"name" => "drivingSide", "type" => "string", "label" => "Driving Side"},
      %{"name" => "safetyRating", "type" => "integer", "label" => "Safety Rating"},
      %{"name" => "carnetRequired", "type" => "boolean", "label" => "Carnet Required"},
      %{"name" => "isoCode", "type" => "string", "label" => "ISO Code"}
    ]
  })
  dataset
end

countries_path = Path.join(File.cwd!(), "priv/data/countries.geojson")

case CountryHelpers.read_geojson(countries_path) do
  %{"features" => features} ->
    count = Enum.reduce(features, 0, fn feature, acc ->
      props = feature["properties"] || %{}
      iso_code = props["ISO_A2"]
      name = props["NAME"] || props["ADMIN"]

      # Skip Antarctica and countries without proper ISO codes
      if iso_code && iso_code != "-99" && iso_code != "AQ" do
        case Datasets.create_dataset_item(%{
          dataset_id: countries_dataset.id,
          name: name,
          description: props["FORMAL_EN"],
          geometry: CountryHelpers.geometry_from_geojson(feature["geometry"]),
          properties: %{
            "continent" => props["CONTINENT"],
            "subregion" => props["SUBREGION"],
            "flagEmoji" => CountryHelpers.flag_emoji(iso_code),
            "drivingSide" => CountryHelpers.driving_side(iso_code),
            "safetyRating" => 3,
            "carnetRequired" => false,
            "isoCode" => iso_code
          }
        }) do
          {:ok, _} -> acc + 1
          {:error, err} ->
            IO.puts("Error importing #{name}: #{inspect(err)}")
            acc
        end
      else
        acc
      end
    end)

    IO.puts("\nImported #{count} countries")

  _ ->
    IO.puts("Error: Could not read countries.geojson")
end

IO.puts("\n=== Complete ===\n")
