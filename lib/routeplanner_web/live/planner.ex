defmodule RouteplannerWeb.Live.Planner do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  require Logger
  use Phoenix.LiveView
  import Ecto.Query
  import Kernel
  alias Routeplanner.Repo
  alias Routeplanner.GoogleMaps
  alias Routeplanner.CourtCases
  alias Routeplanner.CourtCases.CourtCase
  alias Routeplanner.TravellingSalesmen
  alias RouteplannerWeb.Authentication

  # TODO: organize this so less data is transferred over the wire

  use RouteplannerWeb, :live_view

  @days_filter 21

  def fetch_cases(days) do
    # TODO: use eastern timezone
    # TODO: filter and sort in the database
    CourtCases.since_n_days(days)
    |> Enum.sort_by(&(&1.plaintiff))
    |> Enum.filter(fn c -> not c.visited end)
    |> Enum.filter(fn c -> c.status == "Active" end)
  end

  def get_cases(cases, hidden) do
    cases
    |> Enum.filter(fn c -> not MapSet.member?(hidden, c.case_id) end)
  end

  def sum_drive_times(route) do
    route.drive_times
    |> Enum.sum()
    |> (fn secs -> [trunc(secs / 60), rem(trunc(secs), 60)] end).()
    |> Enum.map(&Integer.to_string/1)
    |> Enum.map(fn s -> String.pad_leading(s, 2, "0") end)
    |> Enum.join(":")
    |> (fn t -> Map.put(route, :total_time, t) end).()
  end

  def cases_in_timeframe(route, case_ids) do
    route.cases
    |> Enum.filter(fn c -> Enum.member?(case_ids, c) end)
    |> length
    |> (fn l -> Map.put(route, :cases_shown, l) end).()
  end

  def fetch_routes(cases) do
    case_ids = cases |> Enum.map(&(&1.case_id))
    Routeplanner.Routes.list()
    |> Enum.map(&sum_drive_times/1)
    |> Enum.map(fn r -> cases_in_timeframe(r, case_ids) end)
  end

  def push_cases(socket, event, cases, opts \\ %{}) do
    cases = cases |> Enum.map(&CourtCase.to_encodable/1)
    push_event(socket, event, Map.put(opts, :points, cases))
  end

  def noreply(socket), do: {:noreply, socket}
  def ok(socket), do: {:ok, socket}

  def mount(_params, _session, socket) do
    # only show cases in the past n days
    cases = fetch_cases(@days_filter)
    # show all routes
    routes = fetch_routes(cases)

    socket
    |> assign(routes: routes)
    |> assign(selected_route: nil)
    |> assign(hidden_routes: MapSet.new())
    # court cases
    |> assign(hidden_cases: MapSet.new())
    |> assign(selected_cases: MapSet.new())
    |> assign(court_cases: cases)
    # filters
    |> assign(filters: %{selected: false, days: @days_filter})
    # pager
    |> assign(section: :plan)
    # modal
    |> assign(modal: %{current: nil})
    |> ok
  end

  def handle_event("map_init", %{}, socket) do
    # initialize map when it gets loaded
    map_opts = %{zoom: false, days: @days_filter}
    cases = socket.assigns.court_cases

    socket
    |> push_cases("map-scatter", cases, map_opts)
    |> noreply()
  end

  # Menu Select
  # -----------

  def handle_event("menu_plan", _, socket) do
    socket
    |> assign(section: :plan)
    |> noreply()
  end

  def handle_event("menu_manage", _, socket) do
    socket
    |> assign(section: :manage)
    |> assign(selected_route: nil)
    |> toggle_route(socket.assigns.selected_route)
  end

  # Route Management Page
  # ---------------------

  def handle_event("route_visited", %{"name" => name}, socket) do
    Routeplanner.Routes.toggle_visited!(name)
    cases = fetch_cases(socket.assigns.filters.days)

    socket
    |> assign(routes: fetch_routes(cases))
    |> assign(court_cases: cases)
    |> push_cases("map-scatter", cases)
    |> noreply()
  end

  def unhide_route(socket, route, name) do
    cases = MapSet.difference(socket.assigns.hidden_cases, MapSet.new(route.cases))
    routes = MapSet.delete(socket.assigns.hidden_routes, name)
    {cases, routes}
  end

  def hide_route(socket, route, name) do
    cases = MapSet.union(socket.assigns.hidden_cases, MapSet.new(route.cases))
    routes = MapSet.put(socket.assigns.hidden_routes, name)
    {cases, routes}
  end

  def handle_event("route_hide", %{"name" => name}, socket) do
    route = Routeplanner.Routes.find(name)

    if route.visited do
      noreply(socket)
    else
      {cases, routes} =
        case MapSet.member?(socket.assigns.hidden_routes, name) do
          true -> unhide_route(socket, route, name)
          false -> hide_route(socket, route, name)
        end

      socket
      |> assign(hidden_routes: routes)
      |> assign(hidden_cases: cases)
      |> push_event("map-hide", %{"ids" => MapSet.to_list(cases)})
      |> noreply()
    end
  end

  def handle_event("route_trash", %{"name" => name}, socket) do
    Routeplanner.Routes.toggle_deleted!(name)
    socket
    |> assign(routes: fetch_routes(socket.assigns.court_cases))
    |> noreply()
  end

  def handle_event("show_plan_route", _, socket) do
    if MapSet.size(socket.assigns.selected_cases) == 0 do
      {:noreply, put_flash(socket, :error, "You must select at least one point.")}
    else
      modal = %{}
      |> Map.put(:current, :plan_route)
      |> Map.put(:plan_route, %{cs: Routeplanner.Routes.new()})

      {:noreply, assign(socket, modal: modal)}
    end
  end

  def handle_event("show_import_route", _, socket) do
    modal = %{}
    |> Map.put(:current, :import_route)
    |> Map.put(:import_route, %{cs: Routeplanner.Routes.new()})

    {:noreply, assign(socket, modal: modal)}
  end

  def handle_event("close_modal", _, socket) do
    socket
    |> assign(modal: %{current: nil})
    |> noreply()
  end

  def cases_str_to_list(cases) do
    cases
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 0))
  end

  # TODO: newlines are removed in case id input
  def handle_event("validate_import_route", %{"route" => route}, socket) do
    cs = %{}
    |> Map.put(:name, route["name"])
    |> Map.put(:cases, cases_str_to_list(route["cases"]))
    |> Routeplanner.Routes.verify()

    socket
    |> assign(modal: %{current: :import_route, import_route: %{cs: cs}})
    |> noreply()
  end

  def handle_event("import_route", %{"route" => route}, socket) do
    name = String.trim(route["name"])
    cases = cases_str_to_list(route["cases"])

    case Routeplanner.Routes.add_external(name, cases) do
      {:ok, _} ->
        socket
        |> assign(modal: %{current: nil, import_route: %{cs: nil}})
        |> assign(routes: fetch_routes(socket.assigns.court_cases))
        |> noreply()

      {:error, %Ecto.Changeset{} = cs} ->
        socket
        |> assign(modal: %{current: :import_route, import_route: %{cs: cs}})
        |> noreply()
    end
  end

  defp toggle_route(socket, name) do
    # if there's no route to show fall back on all cases
    if is_nil(name) or socket.assigns.selected_route == name do
      socket
      |> assign(selected_route: nil)
      |> push_event("map-route", %{"points" => []})
      |> noreply
    else
      # TODO: do table join
      cases = Routeplanner.Routes.find(name).cases
      |> Enum.map(&CourtCases.by_id/1)
      |> Enum.map(&CourtCase.to_encodable/1)

      socket
      |> assign(selected_route: name)
      |> push_event("map-route", %{"points" => cases})
      |> noreply
    end
  end

  def handle_event("show_route", %{"name" => name}, socket) do
    # TODO: no double lookup?
    route = Routeplanner.Routes.find(name)
    is_hidden = MapSet.member?(socket.assigns.hidden_routes, name)
    # TODO: replace many is_nil checks with !!
    case {is_hidden, !!route.deleted} do
      {false, false} -> toggle_route(socket, name)
      _ -> {:noreply, socket}
    end
  end

  # Route Planning Page
  # -------------------

  def handle_event("selected_cases", %{"cases" => cases}, socket) do
    {:noreply, assign(socket, selected_cases: MapSet.new(cases))}
  end

  # Case Filters
  # ------------

  def handle_event("filter_days", %{"days-filter" => days_str}, socket) do
    {days, _} = Integer.parse(days_str)
    cases = fetch_cases(days)

    socket
    |> assign(court_cases: cases)
    |> assign(routes: fetch_routes(cases))
    |> push_cases("map-scatter", cases, %{days: days})
    |> noreply()
  end

  def handle_event("toggle_selected", _, socket) do
    selected = not socket.assigns.filters.selected
    socket
    |> assign(filters: %{socket.assigns.filters | selected: selected})
    |> noreply()
  end

  # Route Planning
  # --------------

  def handle_event("plan_route", %{"route" => route}, socket) do
    # find a good path to all cases
    {cases, drive_times} = socket.assigns.selected_cases
    |> MapSet.to_list()
    |> find_short_route()

    record = %{
      name: String.trim(route["name"]),
      cases: cases,
      drive_times: drive_times,
      visited: false,
      deleted: false,
    }

    case Routeplanner.Routes.add(record) do
      {:ok, _} ->
        socket
        |> assign(modal: %{current: nil, plan_route: %{cs: nil}})
        |> assign(routes: fetch_routes(socket.assigns.court_cases))
        |> assign(section: :manage)
        |> assign(selected_route: record.name)
        |> push_event("map-route", %{"points" => cases})
        |> noreply()

      {:error, %Ecto.Changeset{} = cs} ->
        socket
        |> assign(modal: %{current: :plan_route, plan_route: %{cs: cs}})
        |> noreply()
    end
  end

  def find_short_route(cases) do
    # get all matching coordinates from database
    matching = Repo.all(from(
      c in CourtCase,
      where: c.case_id in ^cases,
      select: [:case_id, :latitude, :longitude]
    ))
    # get a list of IDs to match the google response with
    case_ids = matching |> Enum.map(&(&1.case_id))
    # get drive times between all points
    matrix = GoogleMaps.distance_matrix(matching)
    # solve TSP problem
    tsp = TravellingSalesmen.solve(matrix)
    # map to case ids
    case_ids = tsp |> Enum.map(fn i -> Enum.at(case_ids, i) end)
    # get drive times
    times = Enum.zip(Enum.slice(tsp, 0..-2), Enum.slice(tsp, 1..-1))
    |> Enum.map(fn {from, to} -> Enum.at(matrix, from) |> Enum.at(to) end)
    # give back a tuple
    {case_ids, times}
  end
end
