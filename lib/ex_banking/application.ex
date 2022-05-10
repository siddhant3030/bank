defmodule ExBanking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ExBanking.AccountsRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: ExBanking.AccountsSupervisor},
      # Start RateLimiter
      ExBanking.RequestLimit
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExBankingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
