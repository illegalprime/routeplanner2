defmodule Routeplanner.Token do
  @moduledoc """
  Handles creating and validating tokens.
  """
  alias Routeplanner.Accounts.Account
  alias RouteplannerWeb.Endpoint

  @account_verify_salt "Routeplanner is a cooool app"

  def generate_new_account_token(%Account{id: id}) do
    Phoenix.Token.sign(Endpoint, @account_verify_salt, id)
  end

  def verify_new_account_token(token) do
    max_age = 86_400 # tokens that are older than a day should be invalid
    Phoenix.Token.verify(Endpoint, @account_verify_salt, token, max_age: max_age)
  end
end
