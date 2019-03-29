defmodule UnixDS.Supervisor do
  use Supervisor

  # CLIENT

  def start_link(gateway) do
    name = UnixDS.Application.get_name("app")
    Util.Config.app_log("Starting UDS `#{inspect name}`")
    Supervisor.start_link(__MODULE__, gateway, name: name)
  end

  # SERVER

  def init(gateway) do
    socket_path = "/tmp/signalserver/cs-unix"
    name_server = UnixDS.Application.get_name("server")
    name_clientholder = UnixDS.Application.get_name("clientholder")

    Supervisor.init([
      {UnixDS.Server, {name_server, name_clientholder, socket_path, gateway}},
      {UnixDS.ClientHolder, name_clientholder},
    ], strategy: :one_for_one)
  end
end
