defmodule Routeplanner.CourtCases do
  alias Routeplanner.Repo
  alias __MODULE__.CourtCase

  def add(params) do
    %CourtCase{}
    |> CourtCase.new(params)
    |> Repo.insert()
  end
end
