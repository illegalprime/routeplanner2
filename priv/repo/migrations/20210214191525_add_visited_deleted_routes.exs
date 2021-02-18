defmodule Routeplanner.Repo.Migrations.AddVisitedDeletedRoutes do
  use Ecto.Migration

  def change do
    alter table(:routes) do
      add :visited, :boolean
      add :deleted, :boolean
    end
  end
end
