defmodule GrandTour.Repo.Migrations.CreateTours do
  use Ecto.Migration

  def change do
    create table(:tours, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :subtitle, :string
      add :is_public, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tours, [:is_public])
  end
end
