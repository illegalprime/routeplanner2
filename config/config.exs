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
  url: [host: "localhost"],
  secret_key_base: "5kOJMVy9Z3uOpAtLv/7KwEeQt9PqyRcZFTRJXh438uH8E/7fDY8wtjZyc0efvrL2",
  render_errors: [view: RouteplannerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Routeplanner.PubSub,
  live_view: [signing_salt: "Eu0KjZWQ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []},
    identity: {
      Ueberauth.Strategy.Identity, [
        callback_methods: ["POST"],
        uid_field: :username,
        nickname_field: :username
      ]
    },
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: {System, :get_env, ["GOOGLE_CLIENT_ID"]},
  client_secret: {System, :get_env, ["GOOGLE_CLIENT_SECRET"]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
