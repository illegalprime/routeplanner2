defmodule Routeplanner.Repo.Migrations.DateCases do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE court_cases ALTER COLUMN file_date TYPE date USING TO_DATE(file_date, 'MM/DD/YYYY')"
  end
end
