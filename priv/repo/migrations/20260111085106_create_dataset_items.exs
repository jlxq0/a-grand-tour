defmodule GrandTour.Repo.Migrations.CreateDatasetItems do
  use Ecto.Migration

  def change do
    create table(:dataset_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :dataset_id, references(:datasets, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :description, :text
      add :properties, :jsonb, null: false, default: "{}"

      # PostGIS geometry - can be Point, LineString, Polygon, or null
      # Using generic Geometry type to allow any geometry
      add :geometry, :geometry, null: true

      # Images stored as array of URLs
      add :images, {:array, :string}, null: false, default: []

      # Common indexed fields for performance
      add :rating, :integer
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:dataset_items, [:dataset_id])
    create index(:dataset_items, [:name])
    create index(:dataset_items, [:rating])

    # Spatial index using GIST - critical for geo queries
    execute(
      "CREATE INDEX dataset_items_geometry_idx ON dataset_items USING GIST (geometry)",
      "DROP INDEX dataset_items_geometry_idx"
    )

    # GIN index on properties for JSONB containment queries
    execute(
      "CREATE INDEX dataset_items_properties_idx ON dataset_items USING GIN (properties)",
      "DROP INDEX dataset_items_properties_idx"
    )

    # Generated column for bounding box (faster than computing on query)
    execute(
      """
      ALTER TABLE dataset_items
      ADD COLUMN bbox geometry(Polygon, 4326)
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """,
      "ALTER TABLE dataset_items DROP COLUMN bbox"
    )

    # Index on bounding box
    execute(
      "CREATE INDEX dataset_items_bbox_idx ON dataset_items USING GIST (bbox)",
      "DROP INDEX dataset_items_bbox_idx"
    )
  end
end
