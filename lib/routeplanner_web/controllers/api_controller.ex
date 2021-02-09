defmodule RouteplannerWeb.ApiController do
  use RouteplannerWeb, :controller

  def status(conn, _params) do
    render(conn, "status.json", %{})
  end
end
