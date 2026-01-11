defmodule GrandTour.Repo.Migrations.AddCoverImageToTours do
  use Ecto.Migration

  def change do
    alter table(:tours) do
      add :cover_image, :string
    end
  end
end
