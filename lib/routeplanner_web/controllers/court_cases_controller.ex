defmodule RouteplannerWeb.CourtCasesController do
  use RouteplannerWeb, :controller
  alias Routeplanner.CourtCases

  def import_cases(conn, %{"cases" => cases}) do
    # TODO: batch insert / update AND report errors correctly
    Enum.each(cases, fn record ->
      CourtCases.add(record)
    end)
    json(conn, %{result: :ok})
  end
end
