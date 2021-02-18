defmodule RouteplannerWeb.RoutePageController do
  use RouteplannerWeb, :controller
  alias Routeplanner.Routes
  alias Routeplanner.CourtCases

  def show(conn, %{"route" => route}) do
    # TODO: include drive to first location (from meeting point) in drive_times
    route = Routes.find(route)
    cases = route.cases |> Enum.map(&CourtCases.by_id/1)
    route = Map.put(route, :cases, cases)
    render(conn, :show,
      route: route,
      form_link: "https://forms.gle/qy2g4XFEs3dL1BjTA",
    )
  end
end
