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

  use RouteplannerWeb, :live_view

  @days_filter 30

  def fetch_cases(days) do
    # TODO: use eastern timezone
    CourtCases.since_n_days(days)
    |> Enum.sort_by(&(&1.plaintiff))
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

  def fetch_routes() do
    Routeplanner.Routes.list()
    |> Enum.map(&sum_drive_times/1)
  end

  def mount(_params, _session, socket) do
    cases = fetch_cases(@days_filter)
    # NOTE: authentication should be checked here
    {:ok, assign(socket,
        # route managing
        routes: fetch_routes(),
        selected_route: nil,
        # route planning
        court_cases: cases,
        selected_cases: [],
        filters: %{
          selected: false,
          days: @days_filter,
        },
        # pager
        section: :manage,
        map_view: cases,
        map_connect: false,
        # common options
        gmaps_url: Routes.asset_path(socket, :gmaps),
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
    |> toggle_route(socket.assigns.selected_route)
    {:noreply, socket}
  end

  # Route Management Page
  # ---------------------

  def handle_event("show_import_route", _, socket) do
    {:noreply, assign(socket,
        modal: %{
          current: :import_route,
          import_route: %{cs: Routeplanner.Routes.new()},
        },
      )}
  end

  def handle_event("close_import_route", _, socket) do
    {:noreply, assign(socket,
        modal: %{current: nil},
      )}
  end

  def handle_event("validate_route", %{"route" => params}, socket) do
    Logger.warn("route validate: #{inspect(params)}")
    # nicer assign statement
    {:noreply, assign(socket,
        modal: %{
          current: :import_route,
          import_route: %{cs: Routeplanner.Routes.verify(params)},
        },
      )}
  end

  def handle_event("import_route", %{"cases" => cases, "name" => name}, socket) do
    name = String.trim(name)
    cases = cases
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 0))

    Logger.warn("import route #{inspect(cases)}, #{inspect(name)}")
    # {:noreply, assign(socket, modal: nil)}
    {:noreply, socket}
  end

  defp toggle_route(socket, name) do
    # if there's no route to show fall back on all cases
    if is_nil(name) or socket.assigns.selected_route == name do
      socket
      |> assign(selected_route: nil)
      |> assign(map_connect: false)
      |> assign(map_view: socket.assigns.court_cases)
    else
      # TODO: do table join
      cases = Routeplanner.Routes.find(name).cases
      |> Enum.map(&CourtCases.by_id/1)

      assign(socket,
        selected_route: name,
        map_view: cases,
        map_connect: true,
      )
    end
  end

  def handle_event("show_route", %{"name" => name}, socket) do
    {:noreply, toggle_route(socket, name)}
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
