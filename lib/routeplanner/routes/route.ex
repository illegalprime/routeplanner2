defmodule Routeplanner.Routes.Route do
  use Ecto.Schema
  import Ecto.Changeset
  alias Routeplanner.CourtCases

  schema "routes" do
    field :cases, {:array, :string}
    field :drive_times, {:array, :float}
    field :name, :string
    field :visited, :boolean
    field :deleted, :boolean
    field :public_until, :utc_datetime, default: nil

    timestamps()
  end

  @doc false
  def changeset(route, attrs) do
    route
    |> cast(attrs, [:name, :cases, :drive_times, :visited, :deleted, :public_until])
    |> validate_required([:name, :cases, :drive_times])
    |> validate_cases_exist()
    |> unique_constraint(:name)
  end

  # TODO: database exists function
  def validate_cases_exist(cs) do
    case (get_field(cs, :cases) || [])
    |> Enum.filter(fn c -> is_nil(CourtCases.by_id(c)) end) do
      [] -> cs
      not_found ->
        msg = Enum.join(["Case IDs not found"] ++ not_found, " ")
        add_error(cs, :cases, msg)
    end
  end
end
