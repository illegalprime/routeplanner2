defmodule Routeplanner.Repo.Migrations.CreateRoutes do
  use Ecto.Migration

  def change do
    create table(:routes) do
      add :name, :string
      add :cases, {:array, :string}
      add :drive_times, {:array, :float}

      timestamps()
    end

    create unique_index(:routes, [:name])
  end
end
