defmodule GrandTour.Repo.Migrations.CreateUserDatasetPreferences do
  use Ecto.Migration

  def change do
    create table(:user_dataset_preferences, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :dataset_id, references(:datasets, on_delete: :delete_all, type: :binary_id),
        null: false

      add :preferences, :map, default: %{}, null: false

      timestamps()
    end

    create unique_index(:user_dataset_preferences, [:user_id, :dataset_id])
    create index(:user_dataset_preferences, [:user_id])
    create index(:user_dataset_preferences, [:dataset_id])
  end
end
