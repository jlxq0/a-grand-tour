defmodule GrandTour.Repo.Migrations.CreateDatasets do
  use Ecto.Migration

  def change do
    # Enum for geometry types
    execute(
      "CREATE TYPE geometry_type AS ENUM ('point', 'line', 'polygon', 'none')",
      "DROP TYPE geometry_type"
    )

    create table(:datasets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: true
      add :name, :string, null: false
      add :description, :text
      add :geometry_type, :geometry_type, null: false, default: "point"
      add :field_schema, :jsonb, null: false, default: "[]"
      add :display, :jsonb, null: false, default: "{}"
      add :is_system, :boolean, null: false, default: false
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:datasets, [:tour_id])
    create index(:datasets, [:is_system])
    create index(:datasets, [:geometry_type])
  end
end
