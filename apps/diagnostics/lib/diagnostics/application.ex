defmodule Diagnostics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    config = Util.Config.get_config()

    # List all child processes to be supervised
    children = [
      {Diagnostics, {config.gateway.gateway_pid}}
      # Starts a worker by calling: Diagnostics.Worker.start_link(arg)
      # {Diagnostics.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Diagnostics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
