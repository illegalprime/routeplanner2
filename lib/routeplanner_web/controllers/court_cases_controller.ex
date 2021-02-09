defmodule RouteplannerWeb.CourtCasesController do
  use RouteplannerWeb, :controller
  alias Routeplanner.CourtCases

  def import_cases(conn, %{"cases" => cases}) do
    # TODO: batch insert / update AND report errors correctly
    Enum.each(cases, &CourtCases.add/1)
    json(conn, %{result: :ok})
  end
end
