defmodule Routeplanner.Accounts.Whitelist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "whitelist" do
    field :email, :string

    timestamps()
  end

  @doc false
  def changeset(whitelist, attrs) do
    whitelist
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
