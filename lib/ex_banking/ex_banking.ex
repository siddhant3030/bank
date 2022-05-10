defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.Accounts
  alias ExBanking.Accounts.User
  alias ExBanking.RequestLimit

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case Accounts.create_account(user) do
      {:ok, _user} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}


  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount >= 0 do
    with {:ok, account} <- Accounts.get_user_account(user),
         :ok <- RequestLimit.log_request(user) do
      currencies = Map.get(account, :currencies)

      balance = Map.get(currencies, currency, 0.0)

      new_balance =
        (balance + format_amount(amount))
        |> format_amount()

      # Add or update existing currency amount
      currencies = Map.put(currencies, currency, new_balance)

      # Update user account
      account = %User{currencies: currencies}
      Accounts.update_account(user, account)

      {:ok, new_balance}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}


  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount >= 0 and is_binary(currency) do
    with {:ok, account} <- Accounts.get_user_account(user),
         :ok <- RequestLimit.log_request(user) do
      currencies = Map.get(account, :currencies)

      blanace = Map.get(currencies, currency, 0.0)

      if(amount > blanace) do
        {:error, :not_enough_money}
      else
        new_balance =
          (blanace - format_amount(amount))
          |> format_amount()

        # Update existing currency amount
        currencies = Map.put(currencies, currency, new_balance)

        # Update user account
        account = %User{currencies: currencies}
        Accounts.update_account(user, account)

        {:ok, new_balance}
      end
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    with {:ok, account} <- Accounts.get_user_account(user),
         :ok <- RequestLimit.log_request(user) do
      balance =
        Map.get(account, :currencies)
        |> Map.get(currency, 0.00)

      {:ok, balance}
    end
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}


  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and amount >= 0 and
             is_binary(currency) do
    with(
      {:ok, _from_user_account} <- validate_user(from_user, :sender),
      {:ok, _to_user_account} <- validate_user(to_user, :receiver),
      {:ok, from_user_balance} <- from_user_withdraw(from_user, amount, currency),
      {:ok, to_user_balance} <- to_user_deposit(to_user, amount, currency)
    ) do
      {:ok, from_user_balance, to_user_balance}
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  defp validate_user(user, type) do
    with {:ok, account} <- Accounts.get_user_account(user),
         :ok <- RequestLimit.log_request(user) do
      {:ok, account}
    else
      {:error, :too_many_requests_to_user} ->
        reason =
          if type == :sender,
            do: :too_many_requests_to_sender,
            else: :too_many_requests_to_receiver

        {:error, reason}

      {:error, _reason} ->
        reason = if type == :sender, do: :sender_does_not_exist, else: :receiver_does_not_exist
        {:error, reason}
    end
  end

  defp from_user_withdraw(user, amount, currency) do
    case withdraw(user, amount, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_sender}

      other ->
        other
    end
  end

  defp to_user_deposit(user, amount, currency) do
    case deposit(user, amount, currency) do
      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_receiver}

      other ->
        other
    end
  end

  defp format_amount(amount) when is_float(amount) do
    Float.round(amount, 2)
  end

  defp format_amount(amount) when is_integer(amount) do
    amount + 0.0
  end
end
