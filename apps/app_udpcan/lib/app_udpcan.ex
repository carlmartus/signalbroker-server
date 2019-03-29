defmodule CanUdp.App do
  @moduledoc """
  Instance of a UDP server. An instance represents a CAN network.
  """

  use Supervisor

  # CLIENT

  def start_link({namespace, signalbase_pid, conf, server_port, target_host, target_port, type}) when is_atom(namespace) do

    sup_pid = Payload.Name.generate_name_from_namespace(namespace, :supervisor)
    Util.Config.app_log("Starting udpcan `#{inspect sup_pid}`")
    args = {
      Payload.Name.generate_name_from_namespace(namespace, :server),
      Payload.Name.generate_name_from_namespace(namespace, :desc),
      Payload.Name.generate_name_from_namespace(namespace, :writer),
      Payload.Name.generate_name_from_namespace(namespace, :signal),
      Payload.Name.generate_name_from_namespace(namespace, :cache),
      signalbase_pid,
      conf,
      server_port,
      target_host,
      target_port,
      type
    }
    Supervisor.start_link(__MODULE__, args, name: sup_pid)
  end

  # SERVER

  def init({
    server_pid, desc_pid, writer_pid, signal_pid, cache_pid, signalbase_pid, conf,
    server_port, target_host, target_port, type,
  }) do

    Supervisor.init([
      {Payload.Cache, {cache_pid, desc_pid, signal_pid}},
      {Payload.Writer, {writer_pid, server_pid, desc_pid, signal_pid, cache_pid, signalbase_pid, type}},
      {Payload.Signal, {signal_pid, server_pid, desc_pid, cache_pid, writer_pid, signalbase_pid, type}},
      {Payload.Descriptions, {desc_pid, signal_pid, conf, writer_pid}},
      {CanUdp.Server, {server_pid, signal_pid, server_port, target_host, target_port}},
    ], strategy: :one_for_one)
  end

  # INTERNAL

  def make_name(name, postfix) when is_atom(name),
    do: String.to_atom("canudp_"<>Atom.to_string(name)<>"_"<>postfix)
end
