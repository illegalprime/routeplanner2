defmodule Routeplanner.CourtCases do
  import Ecto.Query
  alias Routeplanner.Repo
  alias __MODULE__.CourtCase

  def add(params) do
    %CourtCase{}
    |> CourtCase.new(params)
    |> Repo.insert!(
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: :case_id,
    )
  end

  def list() do
    Repo.all(CourtCase)
  end

  def since_n_days(n) do
    start = Date.add(Date.utc_today(), -n)
    Repo.all(from c in CourtCase, where: c.file_date > ^start)
  end

  def by_id(id) do
    Repo.get_by(CourtCase, case_id: id)
  end

  def mark_visited!(case_id, visited) do
    by_id(case_id)
    |> CourtCase.changeset(%{visited: visited})
    |> Repo.update!()
  end
end
