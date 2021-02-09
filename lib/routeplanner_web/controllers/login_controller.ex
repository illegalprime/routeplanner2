defmodule RouteplannerWeb.LoginController do
  require Logger
  use RouteplannerWeb, :controller
  alias RouteplannerWeb.Authentication
  alias Routeplanner.Accounts

  def index(conn, _params) do
    if Authentication.get_current_account(conn) do
      redirect(conn, to: Routes.profile_path(conn, :show))
    else
        render(conn, :index,
          changeset: Accounts.change_account(),
          action: Routes.login_path(conn, :login)
        )
    end
  end

  def login(conn, %{"account" => %{"email" => email, "password" => pass}}) do
    case email |> Accounts.get_by_email() |> Authentication.authenticate(pass) do
      {:ok, account} ->
        conn
        |> Authentication.log_in(account)
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, :not_verified} ->
        conn
        |> put_flash(:error, "You must verify your email before logging in!")
        |> index(%{})

      {:error, :not_approved} ->
        conn
        |> put_flash(:error, "Your account must be approved by Michael, send him a message!")
        |> index(%{})

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Incorrect email or password")
        |> index(%{})
    end
  end

  def logout(conn, _params) do
    conn
    |> Authentication.log_out()
    |> redirect(to: Routes.login_path(conn, :index))
  end
end
