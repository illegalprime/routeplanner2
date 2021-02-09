defmodule RouteplannerWeb.RegistrationController do
  require Logger
  use RouteplannerWeb, :controller
  plug Ueberauth
  alias Routeplanner.Accounts
  alias Routeplanner.Token
  alias Routeplanner.Email
  alias RouteplannerWeb.Authentication

  def index(conn, _) do
    if Authentication.get_current_account(conn) do
      redirect(conn, to: Routes.page_path(conn, :index))
    else
        render(conn, :index,
          changeset: Accounts.change_account(),
          action: Routes.registration_path(conn, :create))
    end
  end

  def create(%{assigns: %{ueberauth_auth: %{provider: :identity} = auth}} = conn, _) do
    case Accounts.register(auth) do
      {:ok, account} ->
        # generate an email verification token
        token = Token.generate_new_account_token(account)
        # generate the link to send in the email, pointing to our verify route
        verification_url = Routes.registration_url(conn, :verify_email, token: token)
        # send email
        Email.send_account_verification_email(account, verification_url)
        # get the domain of their email to have a nice link on the confirm page
        domain = account.email |> String.split("@") |> List.last()
        # render the page asking a user to check their email
        render(conn, :confirm, email: account.email, domain: domain)

      {:error, changeset} ->
        render(conn, :index,
          changeset: changeset,
          action: Routes.registration_path(conn, :create)
        )
    end
  end

  def verify_email(conn, %{"token" => token}) do
    with {:ok, id} <- Token.verify_new_account_token(token),
         {:ok,  _} <- Accounts.mark_verified(id) do
      conn
      |> put_flash(:info, "Email successfully verified!")
      |> redirect(to: Routes.login_path(conn, :index))
    else
      _ -> conn
      |> put_flash(:error, "The verification token is invalid or has already been used.")
      |> redirect(to: Routes.registration_path(conn, :index))
    end
  end

  def verify_email(conn, _) do
    conn
    |> put_flash(:error, "The verification token is invalid.")
    |> redirect(to: Routes.registration_path(conn, :index))
  end
end
