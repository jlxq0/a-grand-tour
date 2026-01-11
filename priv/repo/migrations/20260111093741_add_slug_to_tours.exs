defmodule GrandTour.Repo.Migrations.AddSlugToTours do
  use Ecto.Migration

  def up do
    # Add column as nullable first
    alter table(:tours) do
      add :slug, :citext
    end

    # Generate slugs for existing tours from name
    execute """
    UPDATE tours
    SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(name, '[^a-zA-Z0-9\\s-]', '', 'g'), '\\s+', '-', 'g'))
    WHERE slug IS NULL
    """

    # Make not null after populating
    alter table(:tours) do
      modify :slug, :citext, null: false
    end

    # Slug must be unique per user
    create unique_index(:tours, [:user_id, :slug])

    # Add name length constraint
    create constraint(:tours, :name_max_length, check: "char_length(name) <= 100")
  end

  def down do
    drop constraint(:tours, :name_max_length)
    drop index(:tours, [:user_id, :slug])

    alter table(:tours) do
      remove :slug
    end
  end
end
