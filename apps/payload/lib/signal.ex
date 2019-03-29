defmodule Payload.Signal do
  use GenServer

  defstruct [
    :self_name, :conn_pid, :desc_pid, :cache_pid, :writer_pid, :signal_server_pid, :type,
    ids_to_decode: %{},
    run_hook: nil,
  ]

  # CLIENT

  @doc """
  Start a CAN-SignalBase interface genserver.
   * `name` name to give the process.
   * `conn_pid` Reference to `Can.Connector` for read/writing.
   * `desc_pid_pid` Reference to `Can.desc_pidriptions` for interpetations.
  """
  def start_link({name, conn_pid, desc_pid, cache_pid, writer_pid, signal_server_pid, type}) do
    GenServer.start_link(__MODULE__, {name, conn_pid, desc_pid, cache_pid, writer_pid, signal_server_pid, type}, name: name)
  end

  def handle_raw_can_frames(pid, source, raw_frames) do
    time_stamp = SignalBase.now()
    GenServer.cast(pid, {:raw_can_frames, raw_frames, source, time_stamp})
  end

  def set_run_hook_on_input_frame(pid, code) do
    GenServer.call(pid, {:set_run_hook, code})
  end


  # SERVER

  def init({self_name, conn_pid, desc_pid, cache_pid, writer_pid, signal_server_pid, type}) do
    state =%__MODULE__{
      self_name: self_name,
      conn_pid: conn_pid,
      desc_pid: desc_pid,
      cache_pid: cache_pid,
      writer_pid: writer_pid,
      signal_server_pid: signal_server_pid,
      type: String.to_atom(type)}

    {:ok, state}
  end

  def handle_call({:set_run_hook, code}, _from, state) do
    {:reply, :ok, %__MODULE__{state | run_hook: code}}
  end

  # def test() do
  #   GenServer.cast(:vcan1_signal, {:signal_server_subscriptions_updated, ["MirrDefrstReq", "PwrEstimdAtStbForClima", "CoolgStsForDisp"]})
  # end

  #TOOO it this fine with cast? does it mean that we could miss a responce in between?
  #build a map with %{id => ["signalA"], id2 => "signalB"}
  def handle_cast({:signal_server_subscriptions_updated, signals}, state) do
    to_decode = Enum.reduce(Payload.Descriptions.get_fields_by_names(state.desc_pid, signals), %{}, fn field, acc ->
    case Map.has_key?(acc, field.id) do
      true -> %{acc | field.id => acc[field.id] ++ [field]}
      false -> Map.put(acc, field.id, [field])
    end
      end)
    state = %__MODULE__{state | ids_to_decode: to_decode}
    {:noreply, state}
  end

  def handle_cast({:raw_flexray_frame, {sid, cycle}, frame, source, time_stamp}, state) do
    process_received_frames([{{sid, cycle}, frame}], source, time_stamp, state)
    {:noreply, state}
  end

  def handle_cast({:raw_can_frames, raw_frames, source, time_stamp},  %__MODULE__{type: t} = state) when t == :can do
    process_received_frames(raw_frames, source, time_stamp, state)
    {:noreply, state}
  end

  # this code allows the signalbroker to connect to networks where lin master is already present. Assumption is that
  # arbritration messages will have the following formmat on arrival {id, payload} = {0x12, ""} as an result of incoming
  # binary represented by 0000003800 (id 0x38, length 0 bytes, se parse_udp_frame)
  def handle_cast({:raw_can_frames, raw_frames, source, time_stamp},  %__MODULE__{type: t} = state) when t == :lin do
    sorted_map = Enum.reduce(raw_frames, %{normal: [], arbitration: []}, fn {id, payload}, acc ->
      case payload do
        "" -> Map.update(acc, :arbitration, [{id, :arbitration}], fn(entry) -> [{id, :arbitration} | entry] end)
        value -> Map.update(acc, :normal, [{id, payload}], fn(entry) -> [{id, payload} | entry] end)
      end
    end)

    Enum.each(sorted_map.arbitration, fn({id, payload} = arb_frame) ->
      # Logger.debug "Sending arb frame #{inspect arb_frame}"
      # publish the signal if someone is listening to it.
      case Map.get(state.ids_to_decode, id) do
        nil -> :no_subscriber
        subscribed_signals ->
          case Payload.Descriptions.get_field_by_id(state.desc_pid, id) do
            nil -> :ignore
            field ->
              name = Enum.find(field.fields, fn(entry) -> (entry.is_frame == true) end).name
              arbitration_frame = {name, payload}
              SignalBase.publish(state.signal_server_pid, [arbitration_frame], source, time_stamp)
          end
      end

      Payload.Writer.lin_flush_penging_messages(state.writer_pid, id)
    end)

    # send the remaing data....
    process_received_frames(sorted_map.normal, source, time_stamp, state)
    {:noreply, state}
  end

  defp process_received_frames(raw_frames, source, time_stamp, state) do
    # Logger.debug "raw frame received #{inspect raw_frames}"
    if state.run_hook do
      state.run_hook.(raw_frames, state)
    end

    Counter.tick_frame(length(raw_frames))

    Enum.map(raw_frames, fn {id, payload} ->
      case Map.get(state.ids_to_decode, id) do
        nil -> :no_subscriber
          Payload.Cache.add_raw_data(state.cache_pid, [{id, payload}])
        subscribed_signals ->
          case identify_frame(id, payload, state.desc_pid) do
            :error -> :ignore
            #%Payload.Descriptions.Frame{fields: fields} ->
            fields ->
              publish_frames(
                state.signal_server_pid, fields,
                subscribed_signals,
                source,
                time_stamp)

              Payload.Cache.add_raw_and_decoded_data(
                state.cache_pid,
                [{id, payload, fields}])
          end
      end
    end)
  end

  # INTERNAL

  defp identify_frame(id, payload, desc_pid),
    do: Payload.Descriptions.get_info_map(desc_pid, id, payload)

  defp publish_frames(pid, channels_with_values, subscribed_signals, source, time_stamp) do
    remaining_signals = Enum.reduce(subscribed_signals, [], fn signal, acc ->
      Enum.reduce(channels_with_values, acc, fn {name, val}, acc ->
    case name == signal.name do
      true -> acc ++ [{name, val}]
      false -> acc
    end
      end)
    end)
    SignalBase.publish(pid, remaining_signals, source, time_stamp)
  end
end
