defmodule GrandTour.Datasets.TourOverride do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Tours.Tour
  alias GrandTour.Datasets.DatasetItem

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tour_overrides" do
    field :overrides, :map, default: %{}
    field :hidden, :boolean, default: false
    field :private_notes, :string

    belongs_to :tour, Tour
    belongs_to :dataset_item, DatasetItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(override, attrs) do
    override
    |> cast(attrs, [:overrides, :hidden, :private_notes, :tour_id, :dataset_item_id])
    |> validate_required([:tour_id, :dataset_item_id])
    |> unique_constraint([:tour_id, :dataset_item_id])
  end
end
