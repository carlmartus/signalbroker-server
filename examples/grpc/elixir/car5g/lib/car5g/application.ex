defmodule Car5g.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Supervisor.child_spec({Car5g,{:runner_5g_client, :tcp_connection}}, id: :car5gClient),
      Supervisor.child_spec({Car5g.Server,{:tcp_connection, :runner_5g_client, '192.168.111.1', 2017}}, id: :tcp_connection)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Car5g.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
