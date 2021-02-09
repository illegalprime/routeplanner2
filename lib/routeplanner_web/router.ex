defmodule RouteplannerWeb.Router do
  use RouteplannerWeb, :router

  # TODO: make OAUTH accounts and then register with email?
  # TODO: email confirmation

  defp api_auth(conn, _opts) do
    password = System.get_env("API_KEY")
    Plug.BasicAuth.basic_auth(conn, username: "api", password: password)
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :secure_api do
    plug :api_auth
  end

  pipeline :guardian do
    plug RouteplannerWeb.Authentication.Pipeline
  end

  pipeline :browser_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", RouteplannerWeb do
    pipe_through [:browser, :guardian]

    get "/login", LoginController, :index
    get "/register", RegistrationController, :index
    get "/verify", RegistrationController, :verify_email
    post "/login", LoginController, :login
    post "/register", RegistrationController, :create
  end

  scope "/auth", RouteplannerWeb do
    pipe_through [:browser, :guardian]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", RouteplannerWeb do
    pipe_through [:browser, :guardian, :browser_auth]

    get "/", PageController, :index
    resources "/profile", ProfileController, only: [:show], singleton: true
    delete "/logout", LoginController, :logout
  end

  # Other scopes may use custom stacks.
  scope "/api", RouteplannerWeb do
    pipe_through :api

    get "/status", ApiController, :status
  end

  scope "/api/import", RouteplannerWeb do
    pipe_through [:api, :secure_api]

    post "/court_cases", CourtCasesController, :import_cases
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: RouteplannerWeb.Telemetry
    end
  end
end
