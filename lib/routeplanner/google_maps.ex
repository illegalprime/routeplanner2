defmodule Routeplanner.GoogleMaps do
  @gmaps_url "https://maps.googleapis.com/maps/api/distancematrix/json"

  def api_key() do
    Application.get_env(:routeplanner, __MODULE__)[:gmaps_api_key]
  end

  defp call_distance_matrix(coords) do
    HTTPoison.get(@gmaps_url, [],
      params: [
        key: api_key(),
        origins: coords,
        destinations: coords,
      ])
  end

  def distance_matrix(points) do
    # transform list into google maps format
    coordinates = points
    |> Enum.map(&("#{&1.latitude},#{&1.longitude}"))
    |> Enum.join("|")

    # do google API query, all pairs distance, then parse
    with {:ok, response} <- call_distance_matrix(coordinates),
         {:ok, all_info} <- Jason.decode(response.body),
         %{"status" => "OK"} <- all_info
    do
      {:ok, all_info["rows"]}
    else
      %{"status" => status} -> {:error, status}
      {:error, error} -> {:error, error}
    end
  end
end
