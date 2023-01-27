defmodule Routeplanner.Repo.Migrations.PublicRoutes do
  use Ecto.Migration

  def change do
    alter table(:routes) do
      add :public_until, :utc_datetime
    end
  end
end
