defmodule Routeplanner.Routes do
  require Logger
  alias Routeplanner.Repo
  alias Routeplanner.GoogleMaps
  alias Routeplanner.CourtCases
  alias __MODULE__.Route

  def rebuild_drive_times(case_ids) do
    # find all the cases
    cases = case_ids |> Enum.map(&CourtCases.by_id/1)
    # split locations into pairs of start and end locations
    starts = Enum.slice(cases, 0..-2)
    ends = Enum.slice(cases, 1..-1)
    pairs = Enum.zip(starts, ends) |> Enum.map(&Tuple.to_list/1)
    # look up drive times between the pairs
    pairs
    |> Enum.map(&GoogleMaps.distance_matrix/1)
    |> Enum.map(fn {:ok, rows} -> Enum.at(rows, 0)["elements"] |> Enum.at(1) end)
    |> Enum.map(fn data -> data["duration"]["value"] end)
  end

  def add_external(name, case_ids) do
    params = %{
      name: name,
      cases: case_ids,
      drive_times: rebuild_drive_times(case_ids),
    }
    %Route{}
    |> Route.changeset(params)
    |> Repo.insert()
  end

  def add(params) do
    %Route{}
    |> Route.changeset(params)
    |> Repo.insert()
  end

  def list() do
    # TODO: do sorting in database
    Repo.all(Route)
    |> Enum.sort_by(&route_sort/1)
    |> Enum.reverse()
  end

  def find(name) do
    Repo.get_by(Route, name: name)
  end

  def new(route \\ %Route{}) do
    Route.changeset(route, %{})
  end

  def toggle_visited!(name) do
    route = find(name)
    visited = is_nil(route.visited) or not route.visited
    # mark cases as visited
    route.cases
    |> Enum.map(fn c -> CourtCases.mark_visited!(c, visited) end)
    # mark route as visited
    Route.changeset(route, %{visited: visited})
    |> Repo.update!()
  end

  def toggle_deleted!(name) do
    route = find(name)
    deleted = is_nil(route.deleted) or not route.deleted
    Route.changeset(route, %{deleted: deleted})
    |> Repo.update!()
  end

  def make_public_until!(route, date) do
    route
    |> Route.changeset(%{public_until: date})
    |> Repo.update!()
  end

  def verify(params) do
    %Route{}
    |> Route.changeset(params)
    |> Map.put(:action, :insert)
  end

  # TODO: import missing routes: R32, R33
  defp route_sort(route) do
    by_number = Regex.scan(~r/\p{Nd}+/, route.name)
    |> Enum.flat_map(fn m -> Enum.map(m, &String.to_integer/1) end)
    |> Enum.concat([route.name])
    not_visited = is_nil(route.visited) or not route.visited
    not_deleted = is_nil(route.deleted) or not route.deleted
    [ not_deleted | [ not_visited | by_number ] ]
  end
end
