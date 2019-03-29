defmodule UnixDS.Client do
  use GenServer, restart: :transient
  #alias SignalBase.Message

  # State
  defmodule State, do: defstruct [
    :socket,
    :name,
    :gateway_pid,
    source: :none,
    subscribe_channel_names: [],
    subscribe_active: false,
    subscribe_blocking: false,
    signal_queue: [],
    timeout_ms: -1, # Timeout in milliseconds
    timeout_pid: nil, # Timeout process pid name
    default_broker: nil,
  ]

  @version 1


  # CLIENT
  # ======

  def start_link({name, _socket, _gateway, _timeout_pid}=params) do
    GenServer.start_link(__MODULE__, params, name: name)
  end


  # SERVER
  # ======

  def init({name, socket, gateway, timeout_pid}) do
    state = %State{
      name: name,
      socket: socket,
      gateway_pid: gateway,
      timeout_pid: timeout_pid,
      default_broker: SignalServerProxy.get_default_namespace(gateway),
    }

    case :erlang.port_info(socket) do
      :undefined -> {:stop, :normal}
      _ -> {:ok, state}
    end
  end

  def handle_info({:tcp, _, data}, state) do
    new_state = case parse_packet(data) do
      {:handshake, source} -> respond_handshake(source, state)
      {:write, name_values} -> respond_write(name_values, state)
      {:read, names} -> respond_read(names, state)
      {:subscribe, names} -> respond_subscribe(names, state)
      :subscribe_start -> respond_subscribe_start(state)
      :subscribe_stop -> respond_subscribe_stop(state)
      :subscribe_continue -> respond_subscribe_continue(state)
      {:timeout_set, ms} -> respond_timeout(ms, state)
      :lin_buses_list -> respond_lin_buses_list(state)
      {:lin_schedules_list, bus_name} -> respond_lin_schedules_list(bus_name, state)
      {:lin_schedules_set, name_values} -> respond_lin_schedules_set(name_values, state)
      {:lin_start, bus_name} -> respond_lin_start(bus_name, state)
      {:lin_stop, bus_name} -> respond_lin_stop(bus_name, state)
    end

    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:stop, :normal, state}
  end


  # INTEGRATION AND RESPONSES
  # =========================

  defp parse_source("") do
    random_stamp = abs(System.monotonic_time())
    String.to_atom("unixds_#{random_stamp}")
  end

  defp parse_source(name), do: String.to_atom(name)

  # Packing / Unpacking for names and values:
  # [{sig1, value1}, {sig2, value2}, ...]
  # and
  # Packing /Unpacking for names only:
  # [sig1, sig2, ...]
  defp seperate_namespaces_unpack({_name, _value}=item), do: item
  defp seperate_namespaces_unpack(name), do: {name, nil}
  defp seperate_namespaces_pack({name, nil}), do: name
  defp seperate_namespaces_pack({_name, _value}=item), do: item

  defp seperate_namespace(name) do
    if String.contains?(name, ":") do
      [b, n] = String.split(name, ":", parts: 2)
      {String.to_atom(b), n}
    else
      {:default, name}
    end
  end

  defp seperate_namespaces(list) do
    Enum.reduce(list, %{}, fn(item, acc) ->
      {name, value} = seperate_namespaces_unpack(item)

      {broker, name} = seperate_namespace(name)
      tup = seperate_namespaces_pack {name, value}

      {_, acc} =
        Map.get_and_update(acc, broker, fn(c) ->
          case c do
            nil -> {nil, [tup]}
            array -> {nil, [tup | array]}
          end
        end)

        acc
    end)
  end

  defp respond_handshake(source, state) do
    %State{state | source: parse_source(source)}
  end

  defp respond_write(name_values, state) do
    name_values
    |> seperate_namespaces()
    |> Enum.map(fn({broker, signals}) ->
      SignalServerProxy.publish(
        state.gateway_pid, signals, state.source, broker)
    end)

    packet_ok() |> send_packet(state.socket)

    state
  end

  defp respond_read(names, state) do
    # Find values
    names =
      names
      |> Enum.map(&(remove_default_broker(&1, state.default_broker)))

    out =
      names
      # Sort by namespaces
      |> seperate_namespaces()
      # Send read command
      |> Enum.flat_map(fn({broker, signals}) ->
        SignalServerProxy.read_values(
          state.gateway_pid, signals, broker)
          |> pack_brocker_namevalues(broker)
      end)

    # Stitch answear together
    names
    |> Enum.map(&seperate_namespace/1)
    |> pack_brocker_tuple()
    |> Enum.map(fn(name) ->
      value = case Enum.find(out, fn({n, _}) ->
        n == name
      end) do
        {_, value} -> value
        _ -> :empty
      end

      {name, value}
    end)
    |> packet_write()
    |> send_packet(state.socket)

    state
  end

  defp respond_subscribe(names, state) do
    packet_ok() |> send_packet(state.socket)

    %State{state | subscribe_channel_names: names}
  end

  defp respond_subscribe_start(state) do
    state.subscribe_channel_names
    |> seperate_namespaces()
    |> Enum.map(fn({broker, signals}) ->
      SignalServerProxy.register_listeners(
        state.gateway_pid, signals,
        state.source, state.name,
        broker)
    end)

    # Start timeout
    UnixDS.Timeout.activate(state.timeout_pid, state.timeout_ms)

    packet_ok() |> send_packet(state.socket)

    %State{state | subscribe_active: true, signal_queue: []}
  end

  defp respond_subscribe_stop(state) do
    SignalServerProxy.remove_listeners(state.gateway_pid, state.name)

    packet_ok() |> send_packet(state.socket)

    %State{state | subscribe_active: false, signal_queue: []}
  end

  defp respond_subscribe_continue(%State{signal_queue: sq}=state)
  when sq == [] do
    packet_ok() |> send_packet(state.socket)

    %State{state | subscribe_blocking: true}
  end

  defp respond_subscribe_continue(state) do
    {msg, rest} = List.pop_at(state.signal_queue, -1)

    # Send OK for continuation
    packet_ok() |> send_packet(state.socket)

    # Followed by immitiade response
    msg.name_values
    |> pack_brocker_namevalues(msg.namespace)
    |> packet_block_event()
    |> send_packet(state.socket)

    %State{state | signal_queue: rest}
  end

  defp respond_timeout(ms, state) do
    packet_ok() |> send_packet(state.socket)
    %State{state | timeout_ms: ms}
  end

  # LIN
  # ===

  defp respond_lin_buses_list(state) do
    config = Util.Config.get_config()
    namespaces =
      config.chains
      |> Enum.filter(fn(x) ->
        x.type == "lin"
      end)
      |> Enum.map(fn(x) ->
        x.namespace
      end)

    packet_read(namespaces)
    |> send_packet(state.socket)

    state
  end

  defp respond_lin_schedules_list([bus_name], state) do
    lin_ldf_file(bus_name)
    |> Map.get(:scheduling) # Get scheduling array
    |> Enum.map(fn(x) -> # Create array of table names
      x.table_name
    end)
    |> packet_read() # Create "read" packet
    |> send_packet(state.socket) # Send packet

    state
  end

  defp respond_lin_schedules_set(name_values, state) do
    [{bus_name, _}, {scheduler_name, repeats}] = name_values

    schedule_file = lin_ldf_file(bus_name)
    pid = Payload.Name.generate_name_from_namespace(String.to_atom(bus_name), :scheduler)
    Lin.Scheduler.run_pattern(pid, schedule_file, scheduler_name, repeats)

    packet_ok()
    |> send_packet(state.socket)

    state
  end

  defp respond_lin_start([bus_name], state) do

    Payload.Name.generate_name_from_namespace(String.to_atom(bus_name), :scheduler)
    |> Lin.Scheduler.start_pattern()

    packet_ok()
    |> send_packet(state.socket)
    state
  end

  defp respond_lin_stop([bus_name], state) do

    Payload.Name.generate_name_from_namespace(String.to_atom(bus_name), :scheduler)
    |> Lin.Scheduler.stop_pattern()

    packet_ok()
    |> send_packet(state.socket)
    state
  end


  # LIN HELPERS
  # ===========

  defp lin_ldf_file(bus_name) do
    Util.Config.get_config() # Read config
    |> Map.get(:chains) # Get chains array
    |> Enum.find(fn(x) -> # Find right chain element
      x.type == "lin" and x.namespace == bus_name
    end)
    |> Map.get(:schedule_file) # Get name of LDF file
    |> Lin.Ldf.parse_file() # Parse LDF
  end


  # SIGNAL HANDLING
  # ===============

  defp pack_brocker_tuple(namespace_names) do
    namespace_names
    |> Enum.map(fn({broker, name}) ->
      "#{broker}:#{name}"
    end)
  end

  defp pack_brocker_namevalues(name_values, broker) do
    name_values
    |> Enum.map(fn({name, value}) ->
      {"#{broker}:#{name}", value}
    end)
  end


  # PACKING VALUES
  # ==============

  defp value_to_binary(:empty), # CS_TYPE_EMPTY
  do: << 0, 0 :: size(64) >>

  defp value_to_binary(value) when is_float(value), # CS_TYPE_F64
  do: << 1, value :: float-native-size(64) >>

  defp value_to_binary(value) when is_integer(value), # CS_TYPE_I64
  do: << 2, value :: signed-native-size(64) >>

  # TODO we should support lin arbitration frames
  defp value_to_binary(_invalid),
  do: << 0, 0 :: size(64) >>

  defp binary_to_value(0, _bin), do: :empty
  defp binary_to_value(1, << value :: float-little-size(64) >>), do: value
  defp binary_to_value(2, << value :: signed-little-size(64) >>), do: value

  # PACKETS
  # =======

  defp packet_ok(), do: packet_header(?o, 0)

  defp packet_write_body([]), do: <<>>
  defp packet_write_body([{write_name, value} | rest]) do
    <<
      byte_size(write_name) + 1 :: unsigned,
      value_to_binary(value) :: binary,
      #sanitize_value(value) :: float-little-size(64),
      write_name :: binary,
      0 :: size(8), # C style end of string NULL terminator
      packet_write_body(rest) :: binary,
    >>
  end

  defp packet_read_body([]), do: <<>>
  defp packet_read_body([name | rest]) do
    <<
      byte_size(name) + 1 :: unsigned,
      name :: binary,
      0 :: size(8), # C style end of string NULL terminator
      packet_read_body(rest) :: binary,
    >>
  end

  defp packet_write(name_values),
    do: <<
      packet_header(?w, length(name_values)) :: binary,
      packet_write_body(name_values) :: binary,
    >>

  defp packet_read(names),
    do: <<
      packet_header(?n, length(names)) :: binary,
      packet_read_body(names) :: binary,
    >>

  defp packet_header(command, signal_count),
    do: <<
      @version :: unsigned,
      command :: unsigned,
      signal_count :: unsigned,
    >>

  defp packet_block_event(name_values) do
    <<
      packet_header(?e, length(name_values)) :: binary,
      packet_write_body(name_values) :: binary,
    >>
  end

  defp packet_timeout(), do: packet_header(?T, 0)

  defp send_packet(packet, socket) do
    :gen_tcp.send(socket, packet)
  end


  # RECIEVE SIGNALS
  # ===============

  def handle_cast({:signal, _msg},
                  %State{subscribe_active: active}=state)
  when active == false do
    # Ignore lingering signals after unsubscription
    {:noreply, state}
  end

  def handle_cast({:signal, msg}, state) do
    if state.signal_queue == [] and state.subscribe_blocking do

      # Send respons
      msg.name_values
      |> pack_brocker_namevalues(msg.namespace)
      |> packet_block_event()
      |> send_packet(state.socket)

      state = %State{state | subscribe_blocking: false}
      {:noreply, state}
    else
      state = %State{state | signal_queue: [msg | state.signal_queue]}
      {:noreply, state}
    end
  end

  def handle_cast(:timeout, %State{subscribe_active: a}=state) when a do
    packet_timeout() |> send_packet(state.socket)
    {:noreply, state}
  end

  # Do nothing if timed out during inactive subscription
  def handle_cast(:timeout, state) do
    {:noreply, state}
  end


  # PARSING
  # =======

  defp parse_packet(bin) do
    <<
      _version :: unsigned,
      command :: unsigned,
      signal_count :: unsigned,
      signals_bin :: binary,
    >> = bin

    case command do
      ?h -> {:handshake, parse_hand_shake(signal_count, signals_bin)}
      ?w -> {:write, parse_write_signals_bin(signal_count, signals_bin)}
      ?r -> {:read, parse_read_signals_bin(signal_count, signals_bin)}
      ?s -> {:subscribe, parse_read_signals_bin(signal_count, signals_bin)}
      ?S -> :subscribe_start
      ?E -> :subscribe_stop
      ?C -> :subscribe_continue
      ?t -> {:timeout_set, parse_timeout_set(signals_bin)}
      ?b -> :lin_buses_list
      ?u -> {:lin_schedules_list, parse_read_signals_bin(1, signals_bin)}
      ?v -> {:lin_schedules_set, parse_write_signals_bin(2, signals_bin)}
      ?l -> {:lin_start, parse_read_signals_bin(1, signals_bin)}
      ?L -> {:lin_stop, parse_read_signals_bin(1, signals_bin)}
    end
  end

  defp parse_hand_shake(signal_count, signals_bin) do
    [source] = parse_read_signals_bin(signal_count, signals_bin)
    source
  end

  defp parse_write_signals_bin(0, _), do: []
  defp parse_write_signals_bin(remaining, bin) do
    <<
      name_len :: unsigned,
      value_type,
      value_bin :: binary-size(8),
      bin :: binary,
    >> = bin

    value = binary_to_value(value_type, value_bin)

    name_len = name_len - 1

    <<
      name :: binary-size(name_len),
      0 :: size(8),
      bin :: binary,
    >> = bin

    [{name, value} | parse_write_signals_bin(remaining-1, bin)]
  end

  defp parse_read_signals_bin(0, _), do: []
  defp parse_read_signals_bin(remaining, bin) do
    <<
      name_len :: unsigned,
      bin :: binary,
    >> = bin

    name_len = name_len - 1

    <<
      name :: binary-size(name_len),
      0 :: size(8),
      bin :: binary,
    >> = bin

    [name | parse_read_signals_bin(remaining-1, bin)]
  end

  defp parse_timeout_set(<<millis :: integer-native-size(32)>> ) do
    millis
  end

  # Change "default:..." namespace to real default namespace "something:..."
  defp remove_default_broker(name, default_broker) do
    case String.split(name, ":", parts: 2) do
      [signal] -> "#{default_broker}:#{signal}"
      ["default", signal] -> "#{default_broker}:#{signal}"
      [namespace, signal] -> "#{namespace}:#{signal}"
    end
  end
end
