defmodule GrandTour.Tours.Tour do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Accounts.User
  alias GrandTour.Tours.Trip
  alias GrandTour.Slug

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tours" do
    field :name, :string
    field :slug, :string
    field :subtitle, :string
    field :is_public, :boolean, default: false
    field :cover_image, :string
    field :cover_image_variants, :map, default: %{}

    belongs_to :user, User
    has_many :trips, Trip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tour, attrs) do
    tour
    |> cast(attrs, [:name, :subtitle, :is_public, :cover_image, :cover_image_variants])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:subtitle, max: 500)
    |> maybe_generate_slug()
    |> validate_length(:slug, max: 64)
    |> unique_constraint([:user_id, :slug])
  end

  defp maybe_generate_slug(changeset) do
    case {get_field(changeset, :slug), get_change(changeset, :name)} do
      {nil, name} when is_binary(name) ->
        put_change(changeset, :slug, Slug.generate(name))

      {_, name} when is_binary(name) ->
        # Name changed, regenerate slug
        put_change(changeset, :slug, Slug.generate(name))

      _ ->
        changeset
    end
  end

  @doc """
  Adds a random suffix to the slug to resolve conflicts.
  Called after a unique constraint violation.
  """
  def with_random_slug_suffix(changeset) do
    slug = get_field(changeset, :slug)

    if slug do
      put_change(changeset, :slug, Slug.with_random_suffix(slug))
    else
      changeset
    end
  end
end
