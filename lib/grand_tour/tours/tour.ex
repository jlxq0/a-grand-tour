defmodule GrandTour.Tours.Tour do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Accounts.User
  alias GrandTour.Tours.Trip

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tours" do
    field :name, :string
    field :subtitle, :string
    field :is_public, :boolean, default: false
    field :cover_image, :string

    belongs_to :user, User
    has_many :trips, Trip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tour, attrs) do
    tour
    |> cast(attrs, [:name, :subtitle, :is_public, :cover_image])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:subtitle, max: 500)
  end
end
