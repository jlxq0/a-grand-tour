defmodule GrandTour.Repo.Migrations.CreateTourAdditions do
  use Ecto.Migration

  def change do
    create table(:tour_additions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false

      add :dataset_id, references(:datasets, type: :binary_id, on_delete: :delete_all),
        null: false

      # Same structure as dataset_items - user's own items added to a system dataset
      add :name, :string, null: false
      add :description, :text
      add :properties, :jsonb, null: false, default: "{}"
      add :geometry, :geometry, null: true
      add :images, {:array, :string}, null: false, default: []
      add :rating, :integer
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:tour_additions, [:tour_id])
    create index(:tour_additions, [:dataset_id])
    create index(:tour_additions, [:tour_id, :dataset_id])
    create index(:tour_additions, [:name])

    # Spatial index
    execute(
      "CREATE INDEX tour_additions_geometry_idx ON tour_additions USING GIST (geometry)",
      "DROP INDEX tour_additions_geometry_idx"
    )

    # GIN index on properties
    execute(
      "CREATE INDEX tour_additions_properties_idx ON tour_additions USING GIN (properties)",
      "DROP INDEX tour_additions_properties_idx"
    )

    # Generated bounding box column
    execute(
      """
      ALTER TABLE tour_additions
      ADD COLUMN bbox geometry(Polygon, 4326)
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """,
      "ALTER TABLE tour_additions DROP COLUMN bbox"
    )

    # Index on bounding box
    execute(
      "CREATE INDEX tour_additions_bbox_idx ON tour_additions USING GIST (bbox)",
      "DROP INDEX tour_additions_bbox_idx"
    )
  end
end
