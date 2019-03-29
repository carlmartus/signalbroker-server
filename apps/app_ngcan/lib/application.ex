defmodule AppNgCan.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do

    config = Util.Config.get_config()
    children =
      config.chains
      |> Enum.filter(fn(conf) -> # Filter out all non-CAN
        conf.type == "can"
      end)
      |> Enum.map(fn(conf) -> # Spawn controller for each CAN network
        namespace = String.to_atom(conf.namespace)
        device = conf.device_name
        conn = Payload.Name.generate_name_from_namespace(namespace, :server)
        desc = Payload.Name.generate_name_from_namespace(namespace, :desc)
        signal = Payload.Name.generate_name_from_namespace(namespace, :signal)
        canwriter = Payload.Name.generate_name_from_namespace(namespace, :writer)
        can_cache =  Payload.Name.generate_name_from_namespace(namespace, :cache)
        id = conf.device_name
        signal_base = conf.device_name
                      |> SignalBase.Application.make_signal_broker_name()

        type = conf.type
        # Create supervised child process
        Supervisor.child_spec(
          {AppNgCan, {
            {device, desc, conn, signal, canwriter, can_cache, signal_base, namespace, type},
            conf}}, id: id)
      end)

    Supervisor.start_link(
      children, strategy: :one_for_one)
  end

  def make_name(device, type) when is_atom(device),
    do: String.to_atom("can_"<>Atom.to_string(device)<>"_"<>type)
end
