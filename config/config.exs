# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :routeplanner,
  ecto_repos: [Routeplanner.Repo]

# Configures the endpoint
config :routeplanner, RouteplannerWeb.Endpoint,
  url: [host: "routeplanner.michaels.toys", scheme: "https", port: 443],
  secret_key_base: "5kOJMVy9Z3uOpAtLv/7KwEeQt9PqyRcZFTRJXh438uH8E/7fDY8wtjZyc0efvrL2",
  render_errors: [view: RouteplannerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Routeplanner.PubSub,
  live_view: [signing_salt: "FmI5-AINE5hA4gDF"]

config :routeplanner, RouteplannerWeb.Authentication,
  issuer: "routeplanner",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

config :routeplanner, RouteplannerWeb.AssetController,
  gmaps_api_key: System.get_env("GMAPS_API_KEY")

config :routeplanner, Routeplanner.GoogleMaps,
  gmaps_api_key: System.get_env("GMAPS_API_KEY")

config :routeplanner, Routeplanner.TravellingSalesmen,
  tsp_bin_path: System.get_env("TSP_BIN_PATH")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]},
    identity: {
      Ueberauth.Strategy.Identity, [
        param_nesting: "account",
        request_path: "/register",
        callback_path: "/register",
        callback_methods: ["POST"],
      ]
    },
  ]

# configure google OAuth
config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: {System, :get_env, ["GOOGLE_CLIENT_ID"]},
  client_secret: {System, :get_env, ["GOOGLE_CLIENT_SECRET"]}

# configure bamboo
config :routeplanner, Routeplanner.Email.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: {System, :get_env, ["SENDGRID_API_KEY"]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
