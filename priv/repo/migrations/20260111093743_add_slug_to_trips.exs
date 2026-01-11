defmodule GrandTour.Repo.Migrations.AddSlugToTrips do
  use Ecto.Migration

  def up do
    # Add column as nullable first
    alter table(:trips) do
      add :slug, :citext
    end

    # Generate slugs for existing trips from name
    execute """
    UPDATE trips
    SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(name, '[^a-zA-Z0-9\\s-]', '', 'g'), '\\s+', '-', 'g'))
    WHERE slug IS NULL
    """

    # Make not null after populating
    alter table(:trips) do
      modify :slug, :citext, null: false
    end

    # Slug must be unique per tour
    create unique_index(:trips, [:tour_id, :slug])

    # Add name length constraint
    create constraint(:trips, :name_max_length, check: "char_length(name) <= 100")
  end

  def down do
    drop constraint(:trips, :name_max_length)
    drop index(:trips, [:tour_id, :slug])

    alter table(:trips) do
      remove :slug
    end
  end
end
