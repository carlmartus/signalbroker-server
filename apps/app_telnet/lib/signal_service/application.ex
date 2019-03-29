defmodule SignalService.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    config = Util.Config.get_config()

    #TODO this should really be the proxy and not the directly signal base.
    signal_base = config.gateway.gateway_pid
    tcp_socket_port = config.gateway.tcp_socket_port

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: SignalService.Worker.start_link(arg1, arg2, arg3)
      # worker(SignalService.Worker, [arg1, arg2, arg3]),
      supervisor(SocketSupervisor, [[]]),
      worker(Task, [SignalService, :accept, [tcp_socket_port, signal_base]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SignalService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
