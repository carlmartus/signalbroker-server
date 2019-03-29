defmodule AppLin do
  @moduledoc """
  Instance of a UDP server. An instance represents a CAN network.
  """

  use Supervisor
  require Logger
  # CLIENT

  def start_link({namespace, signalbase_pid, conf, server_port, target_host, target_port, config_port, node_mode, type}=args) when is_atom(namespace) do

    args = {
      Payload.Name.generate_name_from_namespace(namespace, :server),
      Payload.Name.generate_name_from_namespace(namespace, :desc),
      Payload.Name.generate_name_from_namespace(namespace, :writer),
      Payload.Name.generate_name_from_namespace(namespace, :signal),
      Payload.Name.generate_name_from_namespace(namespace, :cache),
      Payload.Name.generate_name_from_namespace(namespace, :scheduler),
      Payload.Name.generate_name_from_namespace(namespace, :config_server),
      signalbase_pid,
      conf,
      server_port,
      target_host,
      target_port,
      config_port,
      node_mode,
      type
    }
    Supervisor.start_link(__MODULE__, args, name: Payload.Name.generate_name_from_namespace(namespace, :supervisor))
  end

  # SERVER

  def init({
    server_pid, desc_pid, writer_pid, signal_pid, cache_pid, scheduler_pid, config_pid, signalbase_pid, conf,
    server_port, target_host, target_port, config_port, node_mode, type,
  }) do
    Supervisor.init([
      {Payload.Cache, {cache_pid, desc_pid, signal_pid}},
      {Payload.Writer, {writer_pid, server_pid, desc_pid, signal_pid, cache_pid, signalbase_pid, type}},
      {Payload.Signal, {signal_pid, server_pid, desc_pid, cache_pid, writer_pid, signalbase_pid, type}},
      {Payload.Descriptions, {desc_pid, signal_pid, conf, writer_pid}},
      {CanUdp.Server, {server_pid, signal_pid, server_port, target_host, target_port}},
      {Lin.Scheduler, {scheduler_pid, signalbase_pid, server_pid, desc_pid, conf}},
      {Lin.ArduinoConfig, {config_pid, signalbase_pid, desc_pid, server_pid, server_port, target_host, target_port, config_port, node_mode, conf.schedule_file, conf.config.device_identifier}}
    ], strategy: :one_for_one)
  end

  # INTERNAL

  def make_name(name, postfix),
    do: String.to_atom("linudp_"<>Atom.to_string(name)<>"_"<>postfix)
end
