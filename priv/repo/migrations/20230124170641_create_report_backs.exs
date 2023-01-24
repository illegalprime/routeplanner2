defmodule Routeplanner.Repo.Migrations.CreateReportBacks do
  use Ecto.Migration

  def change do
    create table(:report_backs) do
      add :case_id, :string
      add :phone, :string
      add :email, :string
      add :notes, :text
      add :knocked, :boolean, default: false, null: false
      add :talked, :boolean, default: false, null: false
      add :followup, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:report_backs, [:case_id])
  end
end
