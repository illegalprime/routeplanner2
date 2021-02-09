defmodule Routeplanner.Repo.Migrations.CreateWhitelist do
  use Ecto.Migration

  def change do
    create table(:whitelist) do
      add :email, :string

      timestamps()
    end

    create unique_index(:whitelist, [:email])
  end
end
