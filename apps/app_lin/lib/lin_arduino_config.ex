defmodule Lin.ArduinoConfig do
  # TODO make sure to always respond. If we don't have the data query and respond.
  use GenServer;
  require Logger;

  @heartbeat_intervall_in_ms 3_000
  @heartbeat_intervall_in_ms_with_lagg 4_000


  defstruct [
    :desc_pid, :signalbase_pid, :server_pid, :socket, :config_port, :configuration_hash, :node_mode,
    signals_and_sizes: nil,
    master_and_slaves: nil,
    client_com_config: nil,
    heartbeat_timestamp: nil,
    device_identifier: nil,
  ]

  defmodule ClientComConfig, do: defstruct [
    :server_port, :target_host, :target_port
  ]

  defmodule MasterSlave, do: defstruct [
    master: [],
    slaves: [],
    frames: [],
  ]

  defmodule ParsedData do
    defstruct [
        decoded_signals_and_sizes: [],
    ]
  end

  #Client
  #
  def start_link({name, signalbase_pid, desc_pid, server_pid, server_port, target_host, target_port, config_port, node_mode, ldf_file, device_identifier}) do
    GenServer.start_link(__MODULE__, {signalbase_pid, desc_pid, server_pid, server_port, target_host, target_port, config_port, node_mode, ldf_file, device_identifier}, name: name)
  end

  def parse_ids_and_sizes(pid),
    do: GenServer.cast(pid, {:parse_ids_and_sizes})

  defmodule ConfigData do
    defp prepare_signals_and_sizes_local(state, callback) do
      channels = SignalBase.get_channels_by_tag(state.signalbase_pid, :frame, self())
      result =
        case Enum.count(channels) do
          0 -> []
          n -> create_signals_and_sizes(channels, state.desc_pid, state.master_and_slaves) |> IO.inspect
        end
        if callback != nil do
          callback.()
        end

      %ParsedData{decoded_signals_and_sizes: result}
    end

    defp create_signals_and_sizes(channels, desc_pid, master_and_slaves) do
      sizes = Enum.map(channels, fn(channel) ->
        case Payload.Descriptions.get_field_by_name(desc_pid, channel) do
          nil -> {}
          field -> {field.id, round(field.length/8), is_master_id(field.id, master_and_slaves)}
        end
      end)
    end

    defp calculate_hash(signal_and_sizes_vector, com_config, node_mode) do
      # bytes = List.flatten(Enum.map(signal_and_sizes_vector, &Tuple.to_list/1))
      # sha_bytes = bytes ++ node_mode ++
      #   :binary.bin_to_list(<<com_config.server_port::size(16)>>) ++
      #   :binary.bin_to_list(<<com_config.target_port::size(16)>>)
      # <<a::size(16), _::binary>> = :crypto.hash(:sha, sha_bytes)
      # Logger.debug "HASH_BASE #{inspect sha_bytes}"
      # Alternative solution always provide a new number to the clients
      a = rem Lin.ArduinoConfig.now(), 65536
      a
    end

    def prepare_signals_and_sizes(state, callback) do
      signals_and_sizes = prepare_signals_and_sizes_local(state, callback)
      master_slave =
        case state.node_mode do
          "master" -> [1]
          _ -> [0]
        end
      {signals_and_sizes, calculate_hash(signals_and_sizes.decoded_signals_and_sizes, state.client_com_config, master_slave)}
    end

    defp is_master_id(id, %MasterSlave{master: master, frames: frames}) do
      case Enum.find(frames, fn %Lin.Ldf.Frame{id: frame_id} -> frame_id == id end) do
        nil -> Logger.error("Id #{inspect id} missing in ldf file!")
          0
        frame ->
          case [frame.publisher] == master do
            true -> 1
            false -> 0
          end
        end
    end

    def get_slave_master_list(ldf_file) do
      ldf_data = Lin.Ldf.parse_file(ldf_file)
      %MasterSlave{master: ldf_data.master, slaves: ldf_data.slaves, frames: ldf_data.frames}
    end
  end

  def now(), do: System.system_time(:millisecond)

  #Server
  def init({signalbase_pid, desc_pid, server_pid, server_port, target_host, target_port, config_port, node_mode, ldf_file, device_identifier}) do
    # {:ok, socket} = :gen_udp.open(config_port, [:binary, reuseaddr: true])
    # state = %__MODULE__{desc_pid: desc_pid, signalbase_pid: signalbase_pid, socket: socket, target_host: target_host}
    parse_ids_and_sizes(self())
    ldf_file  = if !Util.Config.is_test do
      ldf_file
    else
      "../../" <> ldf_file
    end
    schedule_work(@heartbeat_intervall_in_ms_with_lagg)
    {:ok, %__MODULE__{client_com_config: %ClientComConfig{server_port: server_port, target_host: target_host, target_port: target_port}, desc_pid: desc_pid, signalbase_pid: signalbase_pid, server_pid: server_pid, config_port: config_port, node_mode: node_mode, heartbeat_timestamp: now(), device_identifier: device_identifier, master_and_slaves: ConfigData.get_slave_master_list(ldf_file)}}
  end

# mini protocol
# request
#   header::8, rib_id::8, hash::16, identifier::8, 0::16
# response, payload might be empty if payload_size is 0
#   header::8, rib_id::8, hash::16, identifier::8, payload_size::16, payload::payload_size

# header::8, rib_id::8, identifier::8, payload_size::16, payload::payload_size

  @header 0x03
  @message_sizes 0x04
  @node_mode 0x08
  @port_host 0x01
  @port_client 0x02
  @empty 0x00
  @heartbeat 0x10

  @logger 0x60

# used internally, but still accessible...
  @hash 0x12

  defmacro header, do: @header

  defp send_config_to_client ({:udp, socket, source_ip, inportnumber, id}) do
    Logger.debug "rib #{inspect id} requested full configuration"
    empty_message = [@hash]
    Enum.each(empty_message, fn (identifier) ->
      GenServer.cast(self(), {:udp, socket, source_ip, inportnumber, <<@header, id, 0, 0, identifier, 0, 0>>})
    end)
  end

  def handle_cast({:udp, socket, source_ip, _inportnumber, <<@header, id, _hash::size(16), @message_sizes, 0, 0>>}, state) do
    array = List.flatten(Enum.map(state.signals_and_sizes.decoded_signals_and_sizes, &Tuple.to_list/1))
    send_data(socket, source_ip, @header, id, @message_sizes, array, state)
    {:noreply, state}
  end

  def handle_cast({:udp, socket, source_ip, _, <<@header, id, _hash::size(16), @node_mode, 0, 0>>}, state) do
    data =
    case state.node_mode do
      "master" -> [1]
      _ -> [0]
    end
    send_data(socket, source_ip, @header, id, @node_mode, data, state)
    {:noreply, state}
  end

  def handle_cast({:udp, socket, source_ip, _, <<@header, id, _hash::size(16), @port_host, 0, 0>>}, state) do
    ports =  :binary.bin_to_list(<<state.client_com_config.server_port::size(16)>>)
    send_data(socket, source_ip, @header, id, @port_host, ports, state)
    {:noreply, state}
  end

  def handle_cast({:udp, socket, source_ip, _, <<@header, id, _hash::size(16), @port_client, 0, 0>>}, state) do
    ports = :binary.bin_to_list(<<state.client_com_config.target_port::size(16)>>)
    send_data(socket, source_ip, @header, id, @port_client, ports, state)
    {:noreply, state}
  end

  # request for current hash
  def handle_cast({:udp, socket, source_ip, _, <<@header, id, _hash::size(16), @hash, 0, 0>>}, state) do
    send_data(socket, source_ip, @header, id, @empty, [], state)
    {:noreply, state}
  end

  defp decode_payload(payload_size, payload) do
    case payload_size == byte_size(payload) do
      false -> "Payload size missmatch, reported #{inspect payload_size} received #{inspect byte_size(payload)}"
      true ->
        map = parse_key_value(payload, %{})
        "#{inspect map}"
    end
  end

  defp parse_key_value(<<>>, map) do
    map
  end

  #define HEART_BEAT_SYNC_COUNT (5)
  #define HEART_BEAT_UNSYNCHED_PACKAGES (6)
  #define HEART_BEAT_SYNCHED_PACKAGES (7)

  defp parse_key_value(<<key, value::size(16), remaing :: binary>>, map) do
    key_to_string = %{1 => "TxOverLin", 2 => "RxOverLin", 3 => "TxOverUdp", 4 => "RxOverUdp", 5 => "SynchCount", 6 => "UnSynchedPackages", 7 => "SynchedPackages"}
    atom_from_key = String.to_atom(Map.get(key_to_string, key, "#{inspect key}_unknown_string"))
    # check for duplicate
    case Map.get(map, atom_from_key, nil) do
      nil -> :ok
      old_value -> Logger.warn "Rib reporing duplicated keys. key: #{inspect atom_from_key} value #{inspect old_value} replaced with #{inspect value}"
    end
    parse_key_value(<<remaing :: binary>>, Map.put(map, atom_from_key, value))
  end

  # received hash, potentially request for new configuration.
  def handle_cast({:udp, socket, source_ip, source_port, <<@header, id, hash::size(16), @heartbeat, payload_size::size(16), payload :: binary>>}, state) do
    CanUdp.Server.provide_host_adress(state.server_pid, source_ip)

    message = decode_payload(payload_size, payload)
    Logger.info "Rib #{inspect id} status " <> message
    # check that the clients hash doen't match up. if it doesn't send configuration again
    case hash == state.configuration_hash do
      true ->
        Logger.debug ("client configuration/hash matches server, NOT sending configuration, id: #{inspect id} old hash: #{inspect hash}, new hash: #{inspect state.configuration_hash}")
      false ->
        send_config_to_client({:udp, socket, source_ip, source_port, id})
        Logger.info ("client configuration/hash unsynched, sending new configuration, id: #{inspect id} old hash: #{inspect hash}, new hash: #{inspect state.configuration_hash}")
    end
    {:noreply, %__MODULE__{state | heartbeat_timestamp: now()}}
  end

  # convenience, allows logging for the arduino.
  def handle_cast({:udp, _, _, _, <<@header, id, _hash::size(16), @logger, ll, lh, message :: binary>>}, state) do
    Logger.info "lin message on port: #{inspect state.config_port} #{inspect to_string(:binary.bin_to_list(message))} rib_id #{inspect id}"
    {:noreply, state}
  end

  def handle_cast({:udp, _, source_ip, _, data}, state) do
    Logger.warn "Warning! don't understand UDP/LIN message: #{inspect data} on port #{inspect state.config_port}. Likely version missmatch. Source IP is #{inspect source_ip}"
    {:noreply, state}
  end

  def handle_cast({:parse_ids_and_sizes}, state) do
    {signals_and_sizes, hash} = ConfigData.prepare_signals_and_sizes(state, nil)
    {:noreply, %__MODULE__{state | signals_and_sizes: signals_and_sizes, configuration_hash: hash}}
  end

  defp send_data(socket, ip_dest, header, id, identifier, payload, state) do
    #Logger.debug "Sending udp frame #{inspect frame_id} #{inspect frame_payload} #{inspect data}"
    byte_count = length payload
    hash = :binary.bin_to_list(<<state.configuration_hash::size(16)>>)
    message = [header, id] ++ hash ++ [identifier] ++ :binary.bin_to_list(<<byte_count::size(16)>>) ++ payload
    Logger.debug "Sending #{inspect message} port: #{inspect state.config_port} ip: #{inspect ip_dest}"
    :gen_udp.send(socket, ip_dest, state.config_port, :binary.list_to_bin(message))
  end

  def handle_cast({:signal_server_updated}, state) do
    {signals_and_sizes, hash} = ConfigData.prepare_signals_and_sizes(state, nil)
    state = %__MODULE__{state | signals_and_sizes: signals_and_sizes, configuration_hash: hash}
    {:noreply, state}
  end

  defp schedule_work(intervall_in_ms),
    do: Process.send_after(self(), :check_hearbeat, intervall_in_ms)

  def handle_info(:check_hearbeat, state) do
    schedule_work(@heartbeat_intervall_in_ms_with_lagg)
    elapsed_time = now() - state.heartbeat_timestamp
    cond do
      elapsed_time > @heartbeat_intervall_in_ms_with_lagg ->
        Logger.warn "Rib #{inspect state.device_identifier} not sending hearbeat, been away for #{inspect elapsed_time/1000}s"
      true -> :ok
    end
    {:noreply, state}
  end


end
