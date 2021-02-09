defmodule Routeplanner.Repo.Migrations.CreateCourtCases do
  use Ecto.Migration

  def change do
    create table(:court_cases) do
      add :case_id, :string

      add :name, :string
      add :plaintiff, :string

      add :longitude, :float
      add :latitude, :float
      add :address, :string
      add :street, :string
      add :city, :string
      add :state, :string
      add :zip, :integer

      add :status, :string
      add :judgement, :string
      add :type, :string
      add :file_date, :string
      add :next_event_date, :string
      add :docket, :text

      add :visited, :boolean
      add :active, :boolean

      timestamps()
    end

    create unique_index(:court_cases, [:case_id])
  end
end
