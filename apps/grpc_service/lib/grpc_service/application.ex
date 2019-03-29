defmodule GRPCService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      supervisor(GRPC.Server.Supervisor, [{[Base.FunctionalService.Server, Base.NetworkService.Server, Base.SystemService.Server], 50051}]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GRPCService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_gateway_pid() do
    # config = Util.Config.get_config()
    # Application.get_env(:router_config, :network_config)
    # config.gateway.gateway_pid
    :gateway_pid
  end
end
