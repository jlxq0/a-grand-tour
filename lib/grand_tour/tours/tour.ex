defmodule GrandTour.Tours.Tour do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tours" do
    field :name, :string
    field :subtitle, :string
    field :is_public, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tour, attrs) do
    tour
    |> cast(attrs, [:name, :subtitle, :is_public])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:subtitle, max: 500)
  end
end
