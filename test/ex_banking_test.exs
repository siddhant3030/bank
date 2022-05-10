defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking

describe "All the test related to exbanking" do
  test "Creates the user account" do
    user = "Siddhant"
    assert ExBanking.create_user(user) == :ok
  end

  test "Creates the user account and check if it's an existing user" do
    user = "Singh"
    ExBanking.create_user(user)
    assert ExBanking.create_user(user) == {:error, :user_already_exists}
  end

  test "Deposit amount into an existing user account" do
    user = "Max"
    ExBanking.create_user(user)
    assert ExBanking.deposit(user, 25.25, "USD") == {:ok, 25.25}
  end

  test "Deposit amount into a non-existing user account" do
    user = "bbos"
    assert ExBanking.deposit(user, 25.25, "USD") == {:error, :user_does_not_exist}
  end

  test "Desposit invalid amount into an existing user account" do
    user = "mpas"
    ExBanking.create_user(user)
    assert ExBanking.deposit(user, "25.25", "Euro") == {:error, :wrong_arguments}
  end

  test "Withdraw amount by currency from an existing user acccount" do
    user = "kasd"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "USD")
    assert ExBanking.withdraw(user, 15.25, "USD") == {:ok, 10.0}
  end

  test "Withdraw amount by currency from an existing user acccount before deposit" do
    user = "zupp"
    ExBanking.create_user(user)
    assert ExBanking.withdraw(user, 25.25, "USD") == {:error, :not_enough_money}
  end

  test "Withdraw amount from an existing user account with wrong arguments" do
    user = "medd"
    ExBanking.create_user(user)
    assert ExBanking.withdraw(user, "Euro", 25.25) == {:error, :wrong_arguments}
  end

  test "Get balance of an existing user acccount" do
    user = "lllll"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "USD")
    assert ExBanking.get_balance(user, "USD") == {:ok, 25.25}
  end

  test "Get balance of an existing user account with not available currency" do
    user = "mop"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25.25, "Euro")
    assert ExBanking.get_balance(user, "PKR") == {:ok, 0.00}
  end

  test "Send amount to an existing user account" do
    sender = "Me"
    receiver = "Mel"
    ExBanking.create_user(sender)
    ExBanking.create_user(receiver)

    ExBanking.deposit(sender, 25.25, "Euro")
    ExBanking.deposit(sender, 30.00, "USD")

    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:ok, 15.25, 10.0}
    assert ExBanking.send(sender, receiver, 20.00, "USD") == {:ok, 10.0, 20.0}
  end

  test "Send amount to an existing user account when no money available in sender account" do
    sender = "eminem"
    receiver = "risha"
    ExBanking.create_user(sender)
    ExBanking.create_user(receiver)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :not_enough_money}
  end

  test "Send amount when sender does not exist" do
    sender = "las"
    receiver = "Madasd"
    ExBanking.create_user(receiver)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :sender_does_not_exist}
  end

  test "Send amount when receiver does not exist" do
    sender = "Sasd"
    receiver = "Kelldasder"
    ExBanking.create_user(sender)
    assert ExBanking.send(sender, receiver, 10.00, "Euro") == {:error, :receiver_does_not_exist}
  end

  test "Deposit multiple amounts into existing under limit" do
    user = "sdadslan"
    ExBanking.create_user(user)

    assert Enum.all?(1..10, fn x ->
             {:ok, _balance} = ExBanking.deposit(user, x, "USD")
           end)
  end

  test "Deposit multiple amounts when request limit reached" do
    user = "Kensaddsdo"
    ExBanking.create_user(user)

    assert Enum.any?(1..20, fn x ->
             ExBanking.deposit(user, x, "USD") == {:error, :too_many_requests_to_user}
           end)
  end

  test "Withdraw multiple amounts when request limit reached" do
    user = "Kenosda"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 25, "USD")

    assert Enum.any?(1..20, fn x ->
             ExBanking.withdraw(user, x, "USD") == {:error, :too_many_requests_to_user}
           end)
  end

  test "Withdraw multiple amounts when no money available" do
    user = "Katdasdsadi"
    ExBanking.create_user(user)
    ExBanking.deposit(user, 15, "USD")

    assert Enum.any?(1..20, fn x ->
             ExBanking.withdraw(user, x, "USD") == {:error, :not_enough_money}
           end)
  end
end

end
