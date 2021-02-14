defmodule Routeplanner.Routes.Route do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routes" do
    field :cases, {:array, :string}
    field :drive_times, {:array, :float}
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(route, attrs) do
    route
    |> cast(attrs, [:name, :cases, :drive_times])
    |> validate_required([:name, :cases, :drive_times])
    |> unique_constraint(:name)
  end
end
