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
  alias RouteplannerWeb.Authentication

  # TODO: organize this so less data is transferred over the wire

  use RouteplannerWeb, :live_view

  @days_filter 30

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

  def mount(_params, _session, socket) do
    hidden_cases = MapSet.new()
    cases = fetch_cases(@days_filter)
    # NOTE: authentication should be checked here
    {:ok, assign(socket,
        # route managing
        routes: fetch_routes(cases),
        selected_route: nil,
        hidden_cases: hidden_cases,
        hidden_routes: MapSet.new(),
        # route planning
        court_cases: cases,
        selected_cases: [],
        filters: %{
          selected: false,
          days: @days_filter,
        },
        # pager
        section: :plan,
        map_view: cases,
        map_connect: false,
        # common options
        current_account: nil,
        # modals
        modal: %{
          current: nil,
          import_route: %{},
        }
      )}
  end

  # Menu Select
  # -----------

  def handle_event("menu_plan", _, socket) do
    {:noreply, assign(socket,
        section: :plan,
        # TODO: don't send so much data over the wire
        map_view: socket.assigns.court_cases,
        map_connect: false,
      )}
  end

  def handle_event("menu_manage", _, socket) do
    socket = socket
    |> assign(section: :manage)
    |> assign(selected_route: nil)
    |> toggle_route(name: socket.assigns.selected_route)
    {:noreply, socket}
  end

  # Route Management Page
  # ---------------------

  def handle_event("route_visited", %{"name" => name}, socket) do
    Routeplanner.Routes.toggle_visited!(name)
    cases = fetch_cases(socket.assigns.filters.days)
    {:noreply, assign(socket,
        routes: fetch_routes(socket.assigns.court_cases),
        court_cases: cases,
        map_view: cases,
        map_connect: false,
      )}
  end

  def unhide_route(socket, route, name) do
    cases = MapSet.difference(socket.assigns.hidden_cases, MapSet.new(route.cases))
    routes = MapSet.delete(socket.assigns.hidden_routes, name)
    {:noreply, assign(socket,
        hidden_cases: cases,
        hidden_routes: routes,
      )}
  end

  def hide_route(socket, route, name) do
    cases = MapSet.union(socket.assigns.hidden_cases, MapSet.new(route.cases))
    routes = MapSet.put(socket.assigns.hidden_routes, name)
    {:noreply, assign(socket,
        hidden_cases: cases,
        hidden_routes: routes,
      )}
  end

  def handle_event("route_hide", %{"name" => name}, socket) do
    route = Routeplanner.Routes.find(name)
    case MapSet.member?(socket.assigns.hidden_routes, name) do
      true -> unhide_route(socket, route, name)
      false -> hide_route(socket, route, name)
    end
  end

  def handle_event("route_trash", %{"name" => name}, socket) do
    Routeplanner.Routes.toggle_deleted!(name)
    {:noreply, assign(socket,
        routes: fetch_routes(socket.assigns.court_cases),
      )}
  end

  def handle_event("show_plan_route", _, socket) do
    {:noreply, assign(socket,
        modal: %{
          current: :plan_route,
          plan_route: %{cs: Routeplanner.Routes.new()},
        },
      )}
  end

  def handle_event("show_import_route", _, socket) do
    {:noreply, assign(socket,
        modal: %{
          current: :import_route,
          import_route: %{cs: Routeplanner.Routes.new()},
        },
      )}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket,
        modal: %{current: nil},
      )}
  end

  def cases_str_to_list(cases) do
    cases
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 0))
  end

  # TODO: newlines are removed in case id input
  def handle_event("validate_route", %{"route" => route}, socket) do
    # nicer assign statement
    params = %{
      name: route["name"],
      cases: cases_str_to_list(route["cases"]),
    }
    {:noreply, assign(socket,
        modal: %{
          current: :import_route,
          import_route: %{cs: Routeplanner.Routes.verify(params)},
        },
      )}
  end

  def handle_event("import_route", %{"route" => route}, socket) do
    name = String.trim(route["name"])
    cases = cases_str_to_list(route["cases"])

    case Routeplanner.Routes.add_external(name, cases) do
      {:ok, _} ->
        {:noreply, assign(socket,
            modal: %{current: nil, import_route: %{cs: nil}},
            routes: fetch_routes(socket.assigns.court_cases),
          )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket,
            modal: %{
              current: :import_route,
              import_route: %{cs: changeset},
            },
          )}
    end
  end

  defp toggle_route(socket, opts) do
    # TODO: damn this is so ugly
    name = Keyword.get(opts, :name, Keyword.get(opts, :route, %{name: nil}).name)
    # if there's no route to show fall back on all cases
    if is_nil(name) or socket.assigns.selected_route == name do
      socket
      |> assign(selected_route: nil)
      |> assign(map_connect: false)
      |> assign(map_view: socket.assigns.court_cases)
    else
      # TODO: do table join
      route = Keyword.get(opts, :route, Routeplanner.Routes.find(name))
      cases = route.cases
      |> Enum.map(&CourtCases.by_id/1)

      assign(socket,
        selected_route: name,
        map_view: cases,
        map_connect: true,
      )
    end
  end

  def handle_event("show_route", %{"name" => name}, socket) do
    route = Routeplanner.Routes.find(name)
    is_hidden = MapSet.member?(socket.assigns.hidden_routes, name)
    # TODO: replace many is_nil checks with !!
    case {is_hidden, !!route.deleted} do
      {false, false} -> {:noreply, toggle_route(socket, route: route)}
      _ -> {:noreply, socket}
    end
  end

  # Route Planning Page
  # -------------------

  def handle_event("selected_cases", %{"cases" => cases}, socket) do
    {:noreply, assign(socket, selected_cases: cases)}
  end

  # Case Filters
  # ------------

  def handle_event("filter_days", %{"days-filter" => days_str}, socket) do
    {days, _} = Integer.parse(days_str)
    cases = fetch_cases(days)

    {:noreply, assign(socket,
        court_cases: cases,
        map_view: cases,
        map_connect: false,
        filters: %{socket.assigns.filters | days: days},
      )}
  end

  def handle_event("toggle_selected", _, socket) do
    selected = not socket.assigns.filters.selected
    {:noreply, assign(socket, filters:
        %{socket.assigns.filters | selected: selected}
      )}
  end

  # Route Planning
  # --------------

  def handle_event("plan_route", _, socket) do
    case socket.assigns.selected_cases do
      [] ->
        {:noreply, put_flash(socket, :error, "You must select at least one point.")}

      cases ->
        Logger.warn("PLAN THESE CASES #{inspect(cases)}")
        distance_matrix(cases)
        {:noreply, socket}
    end
  end

  defp distance_matrix(cases) do
    # get all matching coordinates from database
    matching = Repo.all(from(
      c in CourtCase,
      where: c.case_id in ^cases,
      select: [:case_id, :latitude, :longitude]
    ))
    # get a list of IDs to match the google response with
    case_ids = matching |> Enum.map(&(&1.case_id))
    # get drive times between all points
    {:ok, all_info} = GoogleMaps.distance_matrix(matching)
    Logger.warn("gmaps response #{inspect(all_info)}")
    # combine with IDs
    matrix = Enum.zip(case_ids, all_info)
    |> Enum.map(fn ({a, b}) ->
      {a, b["elements"] |> Enum.map(&(&1["duration"]["value"]))}
    end)
    Logger.warn("built matrix #{inspect(matrix)}")
  end
end
