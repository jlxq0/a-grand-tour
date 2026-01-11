defmodule GrandTour.Repo.Migrations.CreateTourOverrides do
  use Ecto.Migration

  def change do
    create table(:tour_overrides, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false

      add :dataset_item_id, references(:dataset_items, type: :binary_id, on_delete: :delete_all),
        null: false

      # User's overridden values for system item fields
      add :overrides, :jsonb, null: false, default: "{}"

      # User can hide system items they don't want to see
      add :hidden, :boolean, null: false, default: false

      # User's private notes/fields for this item
      add :private_notes, :text

      timestamps(type: :utc_datetime)
    end

    # Unique constraint: one override per tour+item combination
    create unique_index(:tour_overrides, [:tour_id, :dataset_item_id])
    create index(:tour_overrides, [:tour_id])
    create index(:tour_overrides, [:dataset_item_id])
  end
end
