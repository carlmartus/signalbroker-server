
defmodule Base.NetworkService.Server do
  use GRPC.Server, service: Base.NetworkService.Service
  require Logger
  alias GRPC.Server
  alias Payload.Descriptions.Frame
  alias Payload.Descriptions.Field

  @gateway_pid GRPCService.Application.get_gateway_pid()

  # TODO raw flag should be used to determine if this makes sence, eg. should only apply to raw signals.
  def encode_binary(value) do
    case value > 0 do
      true ->
        :binary.encode_unsigned(value)
      false ->
        <<>>
    end
  end

  def encode_signals(signals_with_values, timestamp, namespace) do
    Enum.map(signals_with_values, fn {channel, value} ->
      {payload, bytes} = case value do
        :arbitration ->
          {{:arbitration, true}, <<>>}
        :empty ->
          {{:empty, true}, <<>>}
        number ->
          case is_float(value) do
            true ->
              {{:double, value}, <<>>}
            _ ->
              {{:integer, value}, encode_binary(value)}
          end
      end
      case timestamp do
        nil -> Base.Signal.new(payload: payload, raw: bytes, id: Base.SignalId.new(name: channel, namespace: Base.NameSpace.new(name: Atom.to_string(namespace))))
        time -> Base.Signal.new(payload: payload, raw: bytes, timestamp: timestamp, id: Base.SignalId.new(name: channel, namespace: Base.NameSpace.new(name: Atom.to_string(namespace))))
      end
    end)
  end

  # namespace is atom
  def encode_signals(signals_with_values, namespace) do
    encode_signals(signals_with_values, nil, namespace)
  end

  @spec subscribe_to_signals(Base.SubscriberConfig.t, GRPC.Server.Stream.t) :: any
  def subscribe_to_signals(request, stream) do
    name = "grpc_handler" <> inspect self()
    pack_and_send = fn(signals_with_values, timestamp, namespace) ->
      encoded_signals =
        encode_signals(signals_with_values, timestamp, namespace)
      response = Base.Signals.new(signal: encoded_signals)
      Server.stream_send(stream, response)
    end
    GRPCSubscriber.start_link(String.to_atom(name), self(), request.signals.signalId, String.to_atom(request.clientId.id), pack_and_send)
    lock_pid(stream)
  end

  @spec publish_signals(Base.PublisherConfig.t, GRPC.Server.Stream.t) :: any
  def publish_signals(request, _stream) do
    publish_list = Enum.reduce(request.signals.signal, %{},
      fn(%Base.Signal{id: %Base.SignalId{name: signal_name, namespace: %Base.NameSpace{name: namespace}}, payload: packed_payload, raw: bytes}, acc) ->
        # raw has highest priority
        payload = case bytes do
          "" ->
            case packed_payload do
              {:integer, value} -> value
              {:double, value} -> value
              {:arbitration, true} -> :arbitration
              _ -> :error
            end
          bytes ->
            no_bits = byte_size(bytes) * 8
            # default is unsigned
            <<value::size(no_bits)>> = bytes
            value
          _ -> :error
        end

        case payload do
          :error -> acc
          payload -> Map.update(acc, namespace, [{signal_name, payload}], fn(entry) -> [{signal_name, payload} | entry] end)
        end
      end)

    run = fn ->
      Enum.map(publish_list, fn{namespace, signals_with_values} ->
        SignalServerProxy.publish(@gateway_pid, signals_with_values, request.clientId.id, String.to_atom(namespace))
      end)
    end
    wrap_for_hammer("grp_network_handler_name_seed", run, request)

    Base.Empty.new()
  end

  @spec read_signals(Base.SignalIds.t, GRPC.Server.Stream.t) :: Base.Signals.t
  def read_signals(request, _stream) do
    read_list = Enum.reduce(request.signalId, %{}, fn(%Base.SignalId{name: signal_name, namespace: %Base.NameSpace{name: namespace}}, acc) ->
      Map.update(acc, namespace, [signal_name], fn(entry) -> [signal_name | entry] end)
    end)

    values = Enum.reduce(read_list, [], fn({namespace, signals}, acc) ->
      signals_with_values = SignalServerProxy.read_values(@gateway_pid, signals, String.to_atom(namespace))
      encode_signals(signals_with_values, String.to_atom(namespace)) ++ acc
    end)
    Base.Signals.new(signal: values)
  end

  @spec get_configuration(Base.Empty.t, GRPC.Server.Stream.t) :: Base.Configuration.t
  def get_configuration(request, _stream) do
    signal_tree = SignalServerProxy.get_configuration(@gateway_pid)
    networks = Enum.map(signal_tree, fn({namespace, %{type: type}}) ->
      Base.NetworkInfo.new(namespace: Base.NameSpace.new(name: Atom.to_string(namespace)), type: type, description: "")
    end)
    Base.Configuration.new(networkInfo: networks)
  end

  @spec list_signals(Base.NameSpace.t, GRPC.Server.Stream.t) :: Base.Frames.t
  def list_signals(request, _stream) do
    signal_tree = SignalServerProxy.get_channels_tree(@gateway_pid, String.to_atom(request.name))

    frames = Enum.map(signal_tree, fn(%Frame{name: frame, fields: childs, payload_size: payload_size}) ->
      subsignals = Enum.map(childs, fn(%Field{name: name, length: length, is_raw: is_raw}) ->
        meta_data = Base.MetaData.new(description: "", max: 0, min: 0, unit: "", size: length, is_raw: is_raw)
        signal_id = Base.SignalId.new(name: name, namespace: Base.NameSpace.new(name: request.name))
        Base.SignalInfo.new(id: signal_id, metaData: meta_data)
      end)

      meta_data = Base.MetaData.new(description: "", max: 0, min: 0, unit: "", size: payload_size, is_raw: true)
      signal_id = Base.SignalId.new(name: frame, namespace: Base.NameSpace.new(name: request.name))
      signal = Base.SignalInfo.new(id: signal_id, metaData: meta_data)
      Base.FrameInfo.new(signalInfo: signal, childInfo: subsignals)
    end)

    Base.Frames.new(frame: frames)
  end

  defp wrap_for_hammer(pid_unique_seed, run, request) do
    case PeriodicalHammer.start_link(pid_unique_seed, run, request.frequency) do
      :one_shot ->
        run.()
        _ -> :ok
    end
    Base.Empty.new()
  end

  defp lock_pid(_stream) do
    # hang in receive, if we don't lock, the thead will terminate and a be respawn (over and over again)
    # this thread will be killed by server (cowboy) once client disconnets.
    receive do
      :shutdown -> Logger.debug ("End of stream")
    end
  end

end
