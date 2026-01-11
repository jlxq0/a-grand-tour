defmodule GrandTour.Datasets.DatasetItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Datasets.Dataset
  alias GrandTour.Datasets.TourOverride

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "dataset_items" do
    field :name, :string
    field :description, :string
    field :properties, :map, default: %{}
    field :geometry, Geo.PostGIS.Geometry
    field :images, {:array, :string}, default: []
    field :rating, :integer
    field :position, :integer, default: 0

    # bbox is a generated column, read-only
    field :bbox, Geo.PostGIS.Geometry, read_after_writes: true

    belongs_to :dataset, Dataset
    has_many :overrides, TourOverride

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :name,
      :description,
      :properties,
      :geometry,
      :images,
      :rating,
      :position,
      :dataset_id
    ])
    |> validate_required([:name, :dataset_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:images, max: 5)
  end

  @doc """
  Create a point geometry from longitude and latitude.
  """
  def point(lng, lat) do
    %Geo.Point{coordinates: {lng, lat}, srid: 4326}
  end

  @doc """
  Create a line geometry from a list of {lng, lat} tuples.
  """
  def line(coordinates) do
    %Geo.LineString{coordinates: coordinates, srid: 4326}
  end

  @doc """
  Create a polygon geometry from a list of {lng, lat} tuples.
  The first and last coordinate should be the same to close the polygon.
  """
  def polygon(coordinates) do
    %Geo.Polygon{coordinates: [coordinates], srid: 4326}
  end
end
