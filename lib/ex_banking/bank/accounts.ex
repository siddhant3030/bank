defmodule ExBanking.Accounts do
  @moduledoc """
  Documentation to manage the account
  """

  alias ExBanking.Accounts.User
  alias ExBanking.Accounts.Manager

  @doc """
  Create the user account
  """
  @spec create_account(user :: String.t()) :: {:ok, %User{}} | {:error, :user_already_exists}
  def create_account(user) do
    case start_account(user) do
      {:ok} ->
        {:error, :user_already_exists}

      _ ->
        {:ok, Manager.get_user_account(user)}
    end
  end

  @doc """
  Update the user account
  """
  @spec update_account(user :: String.t(), account :: %User{}) :: {:ok}
  def update_account(user, account) do
    Manager.store_changes(user, account)
  end

  @doc """
  Ger the user
  """
  @spec get_user_account(user :: String.t()) :: {:error, :user_does_not_exist} | {:ok, %User{}}
  def get_user_account(user) do
    if account_exists?(user) do
      {:ok, Manager.get_user_account(user)}
    else
      {:error, :user_does_not_exist}
    end
  end

  defp account_exists?(user) do
    case Registry.lookup(ExBanking.AccountsRegistry, user) do
      [{_, _}] ->
        true

      [] ->
        false
    end
  end

  defp start_account(user) do
    case Registry.lookup(ExBanking.AccountsRegistry, user) do
      [{_, _}] ->
        {:ok}

      [] ->
        DynamicSupervisor.start_child(
          ExBanking.AccountsSupervisor,
          {ExBanking.Accounts.Manager, {user}}
        )
    end
  end
end
