defmodule RouteplannerWeb.Authentication.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :routeplanner,
    error_handler: RouteplannerWeb.Authentication.ErrorHandler,
    module: RouteplannerWeb.Authentication

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
