defmodule RouteplannerWeb.PageController do
  use RouteplannerWeb, :controller
  alias RouteplannerWeb.Authentication

  def index(conn, _params) do
    current_account = Authentication.get_current_account(conn)
    render(conn, :index, current_account: current_account)
  end
end
