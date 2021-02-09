defmodule Routeplanner.Email do
  @moduledoc """
  Handles sending email via Bamboo (SendGrid)
  """
  require Logger
  import Bamboo.Email
  alias __MODULE__.Mailer

  def send_account_verification_email(account, url) do
    Logger.warn("EMAIL URL #{url}")

    new_email()
    |> to(account.email)
    |> subject("Account Verification for Route Planner") # TODO: configurable
    |> from("themichaeleden@gmail.com")                  # TODO: configurable
    |> text_body("Click this link to verify your account: #{url}")
    |> Mailer.deliver_now()
  end
end
