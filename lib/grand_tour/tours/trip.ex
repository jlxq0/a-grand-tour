defmodule GrandTour.Tours.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Tours.Tour
  alias GrandTour.Slug

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(planning active completed)

  schema "trips" do
    field :name, :string
    field :slug, :string
    field :subtitle, :string
    field :position, :integer
    field :start_date, :date
    field :end_date, :date
    field :status, :string, default: "planning"

    belongs_to :tour, Tour

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:name, :subtitle, :start_date, :end_date, :status])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:subtitle, max: 500)
    |> validate_inclusion(:status, @statuses)
    |> validate_dates()
    |> validate_required_struct_fields()
    |> maybe_generate_slug()
    |> validate_length(:slug, max: 64)
    |> unique_constraint([:tour_id, :slug])
    |> foreign_key_constraint(:tour_id)
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

  # Validates that tour_id and position are set on the struct
  # (these are set programmatically, not from user input)
  defp validate_required_struct_fields(changeset) do
    changeset
    |> validate_change(:name, fn _, _ ->
      case {get_field(changeset, :tour_id), get_field(changeset, :position)} do
        {nil, _} -> [tour_id: "is required"]
        {_, nil} -> [position: "is required"]
        _ -> []
      end
    end)
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end
end
