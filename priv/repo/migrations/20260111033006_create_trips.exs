defmodule GrandTour.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour_id, references(:tours, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :name, :string, null: false
      add :subtitle, :string
      add :start_date, :date
      add :end_date, :date
      add :status, :string, default: "planning", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:trips, [:tour_id])
    create index(:trips, [:tour_id, :position])
  end
end
