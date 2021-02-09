defmodule Routeplanner.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :email, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string
    field :verified, :boolean
    field :provider, :string

    timestamps()
  end

  def unverified_changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_confirmation(:password, required: true)
    |> put_change(:provider, attrs[:provider])
    |> put_change(:verified, false)
    |> unique_constraint(:email)
    |> put_encrypted_password()
  end

  def verified_changeset(account) do
    account
    |> change
    |> put_change(:verified, true)
  end

  def oauth_changeset(account, attrs) do
    account
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> put_change(:provider, attrs[:provider])
    |> put_change(:verified, true)
    |> unique_constraint(:email)
  end

  defp put_encrypted_password(%{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :encrypted_password, Argon2.hash_pwd_salt(pw))
  end

  defp put_encrypted_password(changeset), do: changeset
end
