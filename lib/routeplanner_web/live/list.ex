defmodule RouteplannerWeb.Live.List do
  use RouteplannerWeb, :live_view
  alias Routeplanner.Repo
  import Ecto.Query, only: [from: 2]

  @limit 8
  @secs2days 60 * 60 * 24

  def mount(_params, _session, socket) do
    show_page(socket, 0)
    |> ok()
  end

  def show_page(socket, no) do
    routes = Repo.all(
      from route in Routeplanner.Routes.Route,
      where: not route.deleted,
      order_by: [desc: :inserted_at],
      select: [:id, :name, :cases, :drive_times, :public_until],
      limit: ^(@limit + 1),
      offset: ^(no * @limit)
    )
    socket
    |> assign(routes: Enum.take(routes, @limit))
    |> assign(now: DateTime.utc_now() |> DateTime.to_unix())
    |> assign(page: %{ no: no, back: no > 0, front: length(routes) > @limit })
  end

  def handle_event("make_route_private", %{"idx" => i}, socket) do
    update_route_expiry(socket, i, nil)
  end

  def handle_event("make_route_public", %{"idx" => i}, socket) do
    expiry = DateTime.add(DateTime.utc_now(), 1 * @secs2days, :seconds)
    update_route_expiry(socket, i, expiry)
  end

  def handle_event("back", _params, socket) do
    case socket.assigns.page do
      %{back: true, no: no} -> show_page(socket, no - 1)
      _ -> socket
    end
    |> noreply()
  end

  def handle_event("forward", _params, socket) do
    case socket.assigns.page do
      %{front: true, no: no} -> show_page(socket, no + 1)
      _ -> socket
    end
    |> noreply()
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
