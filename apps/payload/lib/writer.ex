defmodule Payload.Writer do
  use GenServer
  require Logger
  alias SignalBase.Message
  alias SignalBase.SourceListener

  defstruct [
    :self_name, :conn_pid, :desc_pid, :signal_pid, :cache_pid, :signalbase_pid, :type, :lin_deffered_map
  ]

  defmodule LinDefferedIdEntry, do: defstruct [
    signals: [],
    frames: [],
  ]

  # CLIENT

  def start_link({name, conn_pid, desc_pid, signal_pid, cache_pid, signalbase_pid, type}) do
    GenServer.start_link(__MODULE__, {name, conn_pid, desc_pid, signal_pid, cache_pid, signalbase_pid, type}, name: name)
  end

  def ready_descriptors(pid),
    do: GenServer.cast(pid, :ready_descriptors)


  def init({self_name, conn_pid, desc_pid, signal_pid, cache_pid, signalbase_pid, type}) do
    state =%__MODULE__{
      self_name: self_name,
      conn_pid: conn_pid,
      desc_pid: desc_pid,
      signal_pid: signal_pid,
      cache_pid: cache_pid,
      signalbase_pid: signalbase_pid,
      lin_deffered_map: %{},
      type: String.to_atom(type)}

    {:ok, state}
  end


  def lin_flush_penging_messages(pid, arbitation_frame_id),
    do: GenServer.cast(pid, {:flush_pending_messages, arbitation_frame_id})
  # SERVER

  def handle_cast(:ready_descriptors, state) do

    #|> Payload.Descriptions.get_all_names()
    names_with_tags = Payload.Descriptions.get_all_names_tagged(state.desc_pid)
    SignalBase.register_publisher_with_tags(state.signalbase_pid, names_with_tags, state.conn_pid, %SourceListener{pid: state.signal_pid, source: state.conn_pid})
    channel_names = Enum.map(names_with_tags, fn{name, _} -> name end)
    SignalBase.register_listeners(state.signalbase_pid, channel_names, state.conn_pid, state.self_name)

    if(Util.Config.is_test(),
       do: Util.Forwarder.send({:ready_descriptors, state.signalbase_pid}))

    {:noreply, state}
  end

  def handle_cast({:signal, %Message{name_values: _channels_with_values}}, %__MODULE__{type: t} = state) when t == :flexray do
    Logger.warn "There is no write support for FlexRay."
    {:noreply, state}
  end

  def handle_cast({:signal, %Message{name_values: channels_with_values}}, %__MODULE__{type: t} = state) when t == :can do
    Payload.Descriptions.run_in_context(state.desc_pid, &encode_message_and_dispatch/2, {channels_with_values, state.conn_pid, state.cache_pid})
    {:noreply, state}
  end

  # frames are given precedence over signals. If frame arrives, cached signals for that id is flushed
  def handle_cast({:signal, %Message{name_values: channels_with_values}}, %__MODULE__{type: t} = state) when t == :lin do

    #example %LinDefferedIdEntry{34 => %{frame: [{"ett", 1},{"tva", 2}], signals: [{"sig1", 1},{"sig2", 2}]},
    #                            32 => %{frame: [{"bla", 1},{"gul", 2}], signals: [{"rod", 1}]}}

    # payload would match one of the following
    # {"name", 13}
    # {"name", :arbritration}
    # {"name", {13, :instant}} - this is not implemented

    command_map =
      Enum.reduce(channels_with_values, %{arbitration: [], entry_map: %{}}, fn {channel, value}, acc ->
        case value do
          :arbitration ->
            Map.update(acc, :arbitration, [channel], fn(entry) -> [channel | entry] end)
          _ ->
            case Payload.Descriptions.get_field_by_name(state.desc_pid, channel) do
              [] -> acc
              field ->
                case field.is_frame do
                  true ->
                    %{acc | entry_map: Map.update(acc.entry_map, field.id, %LinDefferedIdEntry{frames: [{channel, value}], signals: []}, fn (%LinDefferedIdEntry{frames: frames} = data) ->
                        # app should not post duplicates. If so there is an application bug
                        %LinDefferedIdEntry{data | frames: [{channel, value}]}
                      end)}
                  _ ->
                    %{acc | entry_map: Map.update(acc.entry_map, field.id, %LinDefferedIdEntry{frames: [], signals: [{channel, value}]}, fn (%LinDefferedIdEntry{signals: signals} = data) ->
                        # don't duplicate
                        filtered_list = Enum.filter(signals, fn {channel_name, _} -> channel_name != channel end)
                        %LinDefferedIdEntry{data | signals: [{channel, value} | filtered_list]}
                      end)}
                end
            end
        end
      end)

    # command_map entry_map now contains %LinDefferedIdEntry for every _new_ frame id.
    # for all the new id:s conclude if it's frames, if so clean out signals. If not frame merge with cached %Lin_deffered_write_cache

    merge_result_new_id =
      Enum.reduce(Map.keys(command_map.entry_map), %{}, fn(id, acc) ->
        id_map = Map.get(command_map.entry_map, id)
        case id_map.frames do
          [] ->
            # merge signals from cached map
            old_signals =
              case Map.get(state.lin_deffered_map, id, []) do
                [] -> []
                id_map -> id_map.signals
              end
            Map.put(acc, id, %LinDefferedIdEntry{id_map | signals: Enum.uniq_by(id_map.signals ++ old_signals, fn {channel, _} -> channel end)})
          [frames] ->
            # remove the signals
            Map.put(acc, id, %LinDefferedIdEntry{id_map | signals: []})
        end
      end)

    # merge maps, on conflict use the new id and it's data
    merge_result_all_ids = Map.merge(state.lin_deffered_map, merge_result_new_id, fn (_id, original, new) -> new end)

    updated_state = %{state | lin_deffered_map: merge_result_all_ids}

    case command_map.arbitration do
      [] -> :empty
      arb_frames ->
        Enum.map(arb_frames, fn (arb_frame) ->
          case Payload.Descriptions.get_field_by_name(state.desc_pid, arb_frame) do
            [] -> :empty
            frame ->
              Lin.Ldf.write_arbitration_frame(state.conn_pid, state.desc_pid, frame)
              lin_flush_pending_messages(frame.id, updated_state)
          end
        end)
    end

    {:noreply, updated_state}
  end

  def handle_cast({:flush_pending_messages, arbitation_frame_id}, state) do
    lin_flush_pending_messages(arbitation_frame_id, state)
    {:noreply, state}
  end

  defp lin_flush_pending_messages(frame_id, state) do
    case Map.get(state.lin_deffered_map, frame_id) do
      nil -> :empty
      %LinDefferedIdEntry{signals: signals, frames: frames} ->
        to_write =
          case frames do
            [] -> signals
            frames -> frames
          end
        Payload.Descriptions.run_in_context(state.desc_pid, &encode_message_and_dispatch/2, {to_write, state.conn_pid, state.cache_pid})
    end
  end

  defp encode_message_and_dispatch({channels_with_values, conn_pid, cache_pid}, desc_state) do
    {packs, names} =
      channels_with_values
      |> Enum.reduce({%{}, %{}}, fn {name, value}, {packets, names_and_value} ->
      Enum.reduce(Payload.Descriptions.extract_fields_by_name(name, desc_state), {packets, names_and_value}, fn field, {packets, names_and_value} ->
        put = {field, value}
        map1 = Map.update(packets, field.id, [put], &([put | &1]))
        put_2 = {name, value}
        map2 = Map.update(names_and_value, field.id, [put_2], &([put_2 | &1]))
        {map1, map2}
      end)
    end)

    packs
    |> Enum.each(fn {can_id, fields_with_values} ->
      payload = Payload.Descriptions.compose_payload(fields_with_values, desc_state)
      Payload.Cache.add_raw_and_decoded_data(cache_pid, [{can_id, payload, Map.get(names, can_id)}])
      Payload.Interface.write(conn_pid, can_id, payload)
    end)
  end
end
