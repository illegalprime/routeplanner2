defmodule RouteplannerWeb.Authentication.ErrorHandler do
  require Logger
  use RouteplannerWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, error, _opts) do
    Logger.warn("auth error: #{inspect(error)}")
    conn
    |> put_flash(:error, "Authentication Error.")
    |> redirect(to: Routes.login_path(conn, :index))
  end
end
