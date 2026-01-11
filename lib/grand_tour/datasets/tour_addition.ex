defmodule GrandTour.Datasets.TourAddition do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Tours.Tour
  alias GrandTour.Datasets.Dataset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tour_additions" do
    field :name, :string
    field :description, :string
    field :properties, :map, default: %{}
    field :geometry, Geo.PostGIS.Geometry
    field :images, {:array, :string}, default: []
    field :rating, :integer
    field :position, :integer, default: 0

    # bbox is a generated column, read-only
    field :bbox, Geo.PostGIS.Geometry, read_after_writes: true

    belongs_to :tour, Tour
    belongs_to :dataset, Dataset

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(addition, attrs) do
    addition
    |> cast(attrs, [
      :name,
      :description,
      :properties,
      :geometry,
      :images,
      :rating,
      :position,
      :tour_id,
      :dataset_id
    ])
    |> validate_required([:name, :tour_id, :dataset_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:images, max: 5)
  end
end
