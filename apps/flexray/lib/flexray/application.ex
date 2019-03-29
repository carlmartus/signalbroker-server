defmodule FlexRay.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = Util.Config.get_config()

    children =
      config.chains
      |> Enum.filter(fn(conf) ->
      conf.type == "flexray"
    end)
    |> Enum.map(fn(conf) ->
        namespace = String.to_atom(conf.namespace)
        target_host = conf.config.target_host |> Util.Config.parse_ip_string()
        target_port = conf.config.target_port
        signal_base = conf.device_name |> SignalBase.Application.make_signal_broker_name()
        server_pid = Payload.Name.generate_name_from_namespace(namespace, :server)
        desc_pid = Payload.Name.generate_name_from_namespace(namespace, :desc)
        writer_pid = Payload.Name.generate_name_from_namespace(namespace, :writer)
        signal_pid = Payload.Name.generate_name_from_namespace(namespace, :signal)
        cache_pid = Payload.Name.generate_name_from_namespace(namespace, :cache)

        Supervisor.child_spec(
          {
            FlexRay,
            {
              namespace,
              {server_pid, desc_pid, writer_pid, signal_pid, cache_pid,
               signal_base, conf, target_host, target_port}
            }
          }, id: conf.device_name)
      end)
    opts = [strategy: :one_for_one, name: FlexRay.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
