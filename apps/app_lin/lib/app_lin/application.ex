defmodule AppLin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp get_target_host(config) do
    case Map.get(config, :target_host) do
      nil -> nil
      host_ip -> Util.Config.parse_ip_string(host_ip)
    end
  end

  def start(_type, _args) do
    config = Util.Config.get_config()

    router_config_port = config.auto_config_boot_server.port

    children =
      config.chains
      |> Enum.filter(fn(conf) -> # Filter out all non-LIN
        conf.type == "lin"
      end)
      |> Enum.map(fn(conf) -> # Spawn controller for each LIN network
        device = conf.device_name
        namespace = conf.namespace
        server_port = conf.config.server_port
        target_host = get_target_host(conf.config)

        target_port = conf.config.target_port
        server_port = conf.config.server_port
        signal_base = SignalBase.Application.make_signal_broker_name(conf.device_name)
        id = conf.namespace
        node_mode = conf.node_mode
        type = conf.type
        # Create supervised child process
        Supervisor.child_spec(
          {
            AppLin,
            {
              String.to_atom(namespace), signal_base, conf,
              server_port, target_host, target_port, router_config_port, node_mode, type
            }
          }, id: id)
      end)


    lin_auto_config =
      config.chains
      |> Enum.filter(fn(conf) -> # Filter out all non-CAN
        conf.type == "lin" and get_target_host(conf.config) == nil
      end)
      |> Enum.reduce(%{}, fn(chain, acc) ->
        # TODO
        # this dependecy here is not wanted.
        config_server = Payload.Name.generate_name_from_namespace(String.to_atom(chain.namespace), :config_server)
        Map.put(acc, chain.config.device_identifier, config_server)
      end)


    # add boot config server process
    lin_config_boot_server = Supervisor.child_spec(
      {Lin.ConfigRouter,
        {String.to_atom(config.auto_config_boot_server.server_pid), config.auto_config_boot_server.port, lin_auto_config}},
      id: "lin_config_router")

    children = [lin_config_boot_server | children]

    opts = [strategy: :one_for_one, name: AppUdplin.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
