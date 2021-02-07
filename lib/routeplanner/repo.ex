defmodule Routeplanner.Repo do
  use Ecto.Repo,
    otp_app: :routeplanner,
    adapter: Ecto.Adapters.Postgres
end
