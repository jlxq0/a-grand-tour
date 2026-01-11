defmodule GrandTour.Datasets.Dataset do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Tours.Tour
  alias GrandTour.Datasets.DatasetItem
  alias GrandTour.Datasets.TourAddition

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @geometry_types ~w(point line polygon none)

  schema "datasets" do
    field :name, :string
    field :description, :string
    field :geometry_type, :string, default: "point"
    field :field_schema, {:array, :map}, default: []
    field :display, :map, default: %{}
    field :is_system, :boolean, default: false
    field :position, :integer, default: 0

    # null tour_id means system dataset
    belongs_to :tour, Tour
    has_many :items, DatasetItem
    has_many :tour_additions, TourAddition

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [
      :name,
      :description,
      :geometry_type,
      :field_schema,
      :display,
      :is_system,
      :position,
      :tour_id
    ])
    |> validate_required([:name, :geometry_type])
    |> validate_inclusion(:geometry_type, @geometry_types)
    |> validate_length(:name, min: 1, max: 255)
  end

  @doc """
  Changeset for creating a system dataset (no tour_id).
  """
  def system_changeset(dataset, attrs) do
    dataset
    |> changeset(attrs)
    |> put_change(:is_system, true)
    |> put_change(:tour_id, nil)
  end

  @doc """
  Changeset for creating a user dataset (requires tour_id).
  """
  def user_changeset(dataset, attrs, tour_id) do
    dataset
    |> changeset(attrs)
    |> put_change(:is_system, false)
    |> put_change(:tour_id, tour_id)
    |> validate_required([:tour_id])
  end
end
