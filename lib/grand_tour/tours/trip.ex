defmodule GrandTour.Tours.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Tours.Tour

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(planning active completed)

  schema "trips" do
    field :name, :string
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
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:subtitle, max: 500)
    |> validate_inclusion(:status, @statuses)
    |> validate_dates()
    |> validate_required_struct_fields()
    |> foreign_key_constraint(:tour_id)
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
