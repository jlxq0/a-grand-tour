defmodule GrandTour.Repo.Migrations.AddUserIdToTours do
  use Ecto.Migration

  def change do
    alter table(:tours) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
    end

    create index(:tours, [:user_id])
  end
end
