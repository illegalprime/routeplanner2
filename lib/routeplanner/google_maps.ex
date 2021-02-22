defmodule Routeplanner.GoogleMaps do
  @gmaps_url "https://maps.googleapis.com/maps/api/distancematrix/json"
  @max_points 10

  def api_key() do
    Application.get_env(:routeplanner, __MODULE__)[:gmaps_api_key]
  end

  def distance_matrix(points) do
    batch_matrix(points, @max_points, fn {to, from} ->
      distance_matrix(to, from) |> to_time_matrix()
    end)
  end

  def distance_matrix(from, to) do
    # transform list into google maps format
    from_coords = from
    |> Enum.map(&("#{&1.latitude},#{&1.longitude}"))
    |> Enum.join("|")

    to_coords = to
    |> Enum.map(&("#{&1.latitude},#{&1.longitude}"))
    |> Enum.join("|")

    # do google API query, all pairs distance, then parse
    with {:ok, response} <- call_distance_matrix(from_coords, to_coords),
         {:ok, all_info} <- Jason.decode(response.body),
           %{"status" => "OK"} <- all_info
      do
      {:ok, all_info["rows"]}
      else
        %{"status" => status} -> {:error, status}
      {:error, error} -> {:error, error}
    end
  end

  defp call_distance_matrix(from_coords, to_coords) do
    HTTPoison.get(@gmaps_url, [],
      params: [
        key: api_key(),
        origins: from_coords,
        destinations: to_coords,
      ])
  end

  def to_time_matrix({:ok, matrix}) do
    Enum.map(matrix, fn row ->
      row["elements"] |> Enum.map(&(&1["duration"]["value"]))
    end)
  end

  def batch_matrix(items, n, f) do
    chunks = Enum.chunk_every(items, n)
    Enum.map(chunks, fn chunk ->
      Enum.map(chunks, fn c -> f.({chunk, c}) end)
    end)
    |> Enum.flat_map(fn matrix ->
      matrix
      |> Enum.zip()
      |> Enum.map(fn row ->
        row
        |> Tuple.to_list()
        |> Enum.concat()
      end)
    end)
  end
end
