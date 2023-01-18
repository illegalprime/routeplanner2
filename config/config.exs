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
  url: [host: "localhost", port: System.get_env("PORT") || 8989],
  secret_key_base: "5kOJMVy9Z3uOpAtLv/7KwEeQt9PqyRcZFTRJXh438uH8E/7fDY8wtjZyc0efvrL2",
  render_errors: [view: RouteplannerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Routeplanner.PubSub,
  live_view: [signing_salt: "FmI5-AINE5hA4gDF"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
    ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" =>
      System.get_env("NODE_PATH") || Path.expand("../deps", __DIR__)
    }
  ]

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
