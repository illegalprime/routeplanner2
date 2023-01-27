defmodule RouteplannerWeb.AuthController do
  use RouteplannerWeb, :controller
  plug Ueberauth

  alias Routeplanner.Accounts
  alias RouteplannerWeb.Authentication

  def callback(%{assigns: %{ueberauth_failure: _}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: Routes.registration_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_or_register(auth) do
      {:ok, account} ->
        case Accounts.is_approved(account.email) do
          true -> conn
          |> Authentication.log_in(account)
          |> redirect(to: "/")

          false -> conn
          |> put_flash(:error, "Your account must be approved by Michael, send him a message!")
          |> redirect(to: Routes.login_path(conn, :login))
        end

      {:error, _error_changeset} ->
        conn
        |> put_flash(:error, "Authentication failed.")
        |> redirect(to: Routes.registration_path(conn, :index))
    end
  end
end
