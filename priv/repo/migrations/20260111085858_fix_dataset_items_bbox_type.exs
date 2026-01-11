defmodule GrandTour.Repo.Migrations.FixDatasetItemsBboxType do
  use Ecto.Migration

  def change do
    # Drop the existing generated column with Polygon constraint
    # and recreate it without the type constraint since ST_Envelope
    # of a Point returns a Point, not a Polygon

    # dataset_items table
    execute(
      "ALTER TABLE dataset_items DROP COLUMN bbox",
      # No-op for rollback, column will be recreated below
      "SELECT 1"
    )

    execute(
      """
      ALTER TABLE dataset_items
      ADD COLUMN bbox geometry
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """,
      "ALTER TABLE dataset_items DROP COLUMN bbox"
    )

    # For rollback, recreate with original Polygon type
    execute(
      # No-op for forward migration
      "SELECT 1",
      """
      ALTER TABLE dataset_items
      ADD COLUMN bbox geometry(Polygon, 4326)
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """
    )

    # tour_additions table
    execute(
      "ALTER TABLE tour_additions DROP COLUMN bbox",
      "SELECT 1"
    )

    execute(
      """
      ALTER TABLE tour_additions
      ADD COLUMN bbox geometry
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """,
      "ALTER TABLE tour_additions DROP COLUMN bbox"
    )

    execute(
      "SELECT 1",
      """
      ALTER TABLE tour_additions
      ADD COLUMN bbox geometry(Polygon, 4326)
      GENERATED ALWAYS AS (ST_Envelope(geometry)) STORED
      """
    )
  end
end
