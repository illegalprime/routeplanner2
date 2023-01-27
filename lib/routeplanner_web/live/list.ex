defmodule RouteplannerWeb.Live.List do
  use RouteplannerWeb, :live_view
  alias Routeplanner.Repo

  @secs2days 60 * 60 * 24

  # TODO: paginate

  def mount(_params, _session, socket) do
    routes = Repo.all(
      Routeplanner.Routes.Route,
      order_by: :inserted_at
    )
    |> Enum.reject(fn r -> r.deleted end)
    |> Enum.reverse()

    socket
    |> assign(routes: routes)
    |> assign(now: DateTime.utc_now() |> DateTime.to_unix())
    |> ok()
  end

  def handle_event("make_route_private", %{"idx" => i}, socket) do
    update_route_expiry(socket, i, nil)
  end

  def handle_event("make_route_public", %{"idx" => i}, socket) do
    expiry = DateTime.add(DateTime.utc_now(), 1 * @secs2days, :seconds)
    update_route_expiry(socket, i, expiry)
  end

  def update_route_expiry(socket, i, date) do
    {i, ""} = Integer.parse(i)
    route = socket.assigns.routes
    |> Enum.at(i)
    |> Routeplanner.Routes.make_public_until!(date)
    socket
    |> assign(routes: List.replace_at(socket.assigns.routes, i, route))
    |> noreply()
  end

  def get_link(socket, route) do
    Routes.live_url(socket, RouteplannerWeb.Live.Route, route.name)
  end
end
