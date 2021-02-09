defmodule Routeplanner.Accounts do
  require Logger
  alias Routeplanner.Repo
  alias __MODULE__.Account
  alias __MODULE__.Whitelist

  def register(%Ueberauth.Auth{provider: :identity} = params) do
    %Account{}
    |> Account.unverified_changeset(extract_account_params(params))
    |> Repo.insert()
  end

  def register(%Ueberauth.Auth{} = params) do
    %Account{}
    |> Account.oauth_changeset(extract_account_params(params))
    |> Repo.insert()
  end

  def whitelist(email) do
    %Whitelist{}
    |> Whitelist.changeset(%{email: email})
    |> Repo.insert()
  end

  def blacklist(email) do
    Repo.get_by(Whitelist, email: email)
    |> Repo.delete()
  end

  def is_approved(email) do
    Repo.get_by(Whitelist, email: email) != nil
  end

  def extract_account_params(
    %{credentials: %{other: other}, info: info, provider: provider}
  ) do
    info
    |> Map.from_struct()
    |> Map.merge(other)
    |> Map.put(:provider, to_string(provider))
  end

  def change_account(account \\ %Account{}) do
    Account.unverified_changeset(account, %{})
  end

  def get_account(id) do
    Repo.get(Account, id)
  end

  def get_by_email(email) do
    Repo.get_by(Account, email: email)
  end

  def get_or_register(%Ueberauth.Auth{info: %{email: email}} = params) do
    if account = get_by_email(email) do
      {:ok, account}
    else
      register(params)
    end
  end

  def mark_verified(id) do
    with %Account{verified: false} <- get_account(id) do
      get_account(id)
      |> Account.verified_changeset()
      |> Repo.update()
    else
      _ -> {:error, :already_verified}
    end
  end
end
