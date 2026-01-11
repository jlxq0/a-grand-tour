defmodule GrandTour.Datasets.UserDatasetPreference do
  use Ecto.Schema
  import Ecto.Changeset

  alias GrandTour.Accounts.User
  alias GrandTour.Datasets.Dataset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_dataset_preferences" do
    # Preferences map structure:
    # %{
    #   "view_type" => "list" | "table" | "card",
    #   "visible_fields" => ["name", "description", ...],
    #   "sort_field" => "name",
    #   "sort_direction" => "asc" | "desc",
    #   "default_filter" => nil | "some filter text",
    #   "card_style" => "image_overlay" | "metadata"
    # }
    field :preferences, :map, default: %{}

    belongs_to :user, User
    belongs_to :dataset, Dataset

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [:preferences, :user_id, :dataset_id])
    |> validate_required([:user_id, :dataset_id])
    |> validate_preferences()
    |> unique_constraint([:user_id, :dataset_id])
  end

  defp validate_preferences(changeset) do
    case get_change(changeset, :preferences) do
      nil ->
        changeset

      prefs when is_map(prefs) ->
        # Validate view_type if present
        case Map.get(prefs, "view_type") do
          nil -> changeset
          type when type in ["list", "table", "card"] -> changeset
          _ -> add_error(changeset, :preferences, "invalid view_type")
        end

      _ ->
        add_error(changeset, :preferences, "must be a map")
    end
  end
end
