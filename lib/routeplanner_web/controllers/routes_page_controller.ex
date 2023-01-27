defmodule RouteplannerWeb.RoutesPageController do
  use RouteplannerWeb, :controller
  alias Routeplanner.Routes

  def list(conn, _params) do
    render(conn, :list,
      routes: Routes.list() |> Enum.reject(fn r -> r.deleted end)
    )
  end
end
