defmodule Routeplanner.Repo.Migrations.AddAccountEmailVerifyAndProvider do
  use Ecto.Migration

  # https://devhints.io/phoenix-migrations
  # https://devhints.io/phoenix-ecto
  def change do
    alter table(:accounts) do
      add :verified, :boolean
      add :provider, :string
    end
  end
end
