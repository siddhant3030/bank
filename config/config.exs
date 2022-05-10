# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :ex_banking,
  max_requests: 10,
  rate_units: :seconds,
  sweep_rate: 60
