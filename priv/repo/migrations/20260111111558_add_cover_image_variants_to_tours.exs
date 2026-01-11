defmodule GrandTour.Repo.Migrations.AddCoverImageVariantsToTours do
  use Ecto.Migration

  def change do
    alter table(:tours) do
      add :cover_image_variants, :map, default: %{}
    end
  end
end
