defmodule GrandTour.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def up do
    # Add column as nullable first
    alter table(:users) do
      add :username, :citext
    end

    # Generate usernames for existing users from email prefix
    # Use a CTE to handle duplicates by appending row number
    execute """
    WITH ranked AS (
      SELECT id,
             LOWER(SUBSTRING(email FROM '^[^@]+')) AS base_username,
             ROW_NUMBER() OVER (PARTITION BY LOWER(SUBSTRING(email FROM '^[^@]+')) ORDER BY inserted_at) AS rn
      FROM users
    )
    UPDATE users
    SET username = CASE
      WHEN ranked.rn = 1 THEN ranked.base_username
      ELSE ranked.base_username || ranked.rn::text
    END
    FROM ranked
    WHERE users.id = ranked.id AND users.username IS NULL
    """

    # Make not null after populating
    alter table(:users) do
      modify :username, :citext, null: false
    end

    create unique_index(:users, [:username])
  end

  def down do
    drop index(:users, [:username])

    alter table(:users) do
      remove :username
    end
  end
end
