defmodule RouteplannerWeb.AssetController do
  @moduledoc """
  Controller for loading assets protected in some way (e.g. API keys).
  """
  require Logger
  use RouteplannerWeb, :controller

  # Google Map's Client JS is protected by an API Key in its query params
  def gmaps(conn, _params) do
    options = [
      params: [
        key: Application.get_env(:routeplanner, __MODULE__)[:gmaps_api_key],
        callback: "initMap",
        libraries: "",
        v: "weekly",
      ]
    ]
    case HTTPoison.get("https://maps.googleapis.com/maps/api/js", [], options) do
      { :ok, response } ->
        conn
        |> put_resp_content_type("application/javascript")
        |> text(response.body)
      { :error, _error } ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{status: :error})
    end
  end
end
