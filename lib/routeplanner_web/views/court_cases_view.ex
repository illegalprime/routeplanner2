defmodule RouteplannerWeb.CourtCasesView do
  use RouteplannerWeb, :view

  def render("status.json", _params) do
    %{status: :ok}
  end
end
