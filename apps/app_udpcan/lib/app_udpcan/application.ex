defmodule CanUdp.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = Util.Config.get_config()

    children =
      config.chains
      |> Enum.filter(fn(conf) -> # Filter out all non-CAN
        conf.type == "udp"
      end)
      |> Enum.map(fn(conf) -> # Spawn controller for each CAN network
        namespace = String.to_atom(conf.namespace)
        server_port = conf.server_port
        target_host = conf.target_host |> Util.Config.parse_ip_string()
        target_port = conf.target_port
        signal_base = conf.device_name
                      |> SignalBase.Application.make_signal_broker_name()
        type = conf.type

        # Create supervised child process
        Supervisor.child_spec({
            CanUdp.App, {
              namespace, signal_base, conf,
              server_port, target_host, target_port, type
            }
          }, id: conf.device_name)
      end)

    opts = [strategy: :one_for_one, name: AppUdpcan.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
