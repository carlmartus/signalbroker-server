defmodule Payload.Cache do

  use GenServer;
  require Logger;

  defstruct [
    ets_id_to_raw: nil, desc_pid: nil,
    ets_id_to_unpacked: nil
  ]

  #Client

  def start_link({name, desc_pid, _}) do
    GenServer.start_link(__MODULE__, desc_pid, name: name)
  end

  def read_channels(pid, channel_names),
    do: GenServer.call(pid, {:read_cache, channel_names})

  def add_raw_and_decoded_data(pid, [{frame_id, payload, fields_with_values}]),
    do: GenServer.cast(pid, {:write_raw_and_decoded_data, [{frame_id, payload, fields_with_values}]})

  def add_raw_data(pid, [{frame_id, payload}]),
    do: GenServer.cast(pid, {:write_raw_data, [{frame_id, payload}]})

  #purely for testing
  def get_nbr_entries(pid),
    do: GenServer.call(pid, {:nbr_entries})

  #purely for testing
  def get_nbr_entries_unpacked(pid),
    do: GenServer.call(pid, {:nbr_entries_unpacked})


  #Server
  def init(desc_pid) do
    id_to_raw = :ets.new(CacheTableRaw, [:set, :private])
    id_to_unpacked = :ets.new(CacheTableUnpacked, [:set, :private])
    {:ok, %__MODULE__{ets_id_to_raw: id_to_raw, ets_id_to_unpacked: id_to_unpacked, desc_pid: desc_pid}}
  end

  def handle_cast({:write_raw_data, raw_frames}, state) do
    # Logger.debug "data raw received #{inspect raw_frames}"
    raw_frames
    |> Enum.map(fn {id, payload} ->
      :ets.insert(state.ets_id_to_raw, {id, payload})
      :ets.delete(state.ets_id_to_unpacked, id)
    end)
    # Logger.debug ("Store #{inspect raw_frames}, cache size is now #{inspect :ets.info(state.ets_id_to_raw)} #{inspect :ets.info(state.ets_id_to_unpacked)}")

    if(Util.Config.is_test(), do: Util.Forwarder.send(:cache_update))

    {:noreply, state}
  end


  def handle_cast({:write_raw_and_decoded_data, raw_frames_with_values}, state) do
    # Logger.debug "data received #{inspect raw_frames_with_values}"
    raw_frames_with_values
    |> Enum.map(fn {id, data, decoded_data} ->
      :ets.insert(state.ets_id_to_raw, {id, data})
      :ets.insert(state.ets_id_to_unpacked, {id, decoded_data})
    end)
    # Logger.debug ("Store #{inspect raw_frames_with_values}, cache size is now #{inspect :ets.info(state.ets_id_to_raw)} #{inspect :ets.info(state.ets_id_to_unpacked)}")

    if(Util.Config.is_test(), do: Util.Forwarder.send(:cache_decoded))

    {:noreply, state}
  end

  defp identify_frame(id, payload, desc_pid),
    do: Payload.Descriptions.get_info_map(desc_pid, id, payload)

  defp get_channel_by_id(id, channel, state) do
    # first check the local cache
    case :ets.lookup(state.ets_id_to_unpacked, id) do
      [{_, decoded_data}] ->
        # match in id_decoded cache
        # Logger.debug "found value in decoded cache"
        case Enum.filter(decoded_data, fn ({name, _}) -> name == channel end) do
          [value] -> value
          [] ->
            # id is located, but the specific channel is missing.
            get_channel_by_id_from_raw(id, channel, state)
        end
      [] ->
        # no match, decode from the id_raw cache
        get_channel_by_id_from_raw(id, channel, state)
    end
  end

  defp get_channel_by_id_from_raw(id, channel, state) do
    case :ets.lookup(state.ets_id_to_raw, id) do
      [{id, value}] ->
        case identify_frame(id, value, state.desc_pid) do
          :error ->
            {channel, :empty}
          signals_with_values ->
            # Logger.debug "had to decode data, it should now be in the cache"
            :ets.insert(state.ets_id_to_unpacked, {id, signals_with_values})
            [value] = Enum.filter(signals_with_values, fn ({name, _}) -> name == channel end)
            value
        end
      [] ->
        {channel, :empty}
    end
  end

  # TODO we can inccread by trying to optimise teh resolving channel to id. Now this is done by bouncing to desc
  def handle_call({:read_cache, channel_names}, _from, state) do
    fields = Payload.Descriptions.get_fields_by_names(state.desc_pid, channel_names)

    cached_values =
      Enum.reduce(channel_names, [], fn name, acc ->
    [case Enum.find(fields, :empty, fn x -> x.name == name end) do
      :empty -> {name, :empty}
      f -> get_channel_by_id(f.id, f.name, state)
    end] ++ acc
      end)

    {:reply, cached_values, state}
  end

  #purely for testing
  def handle_call({:nbr_entries}, _from, state) do
    size = :ets.info(state.ets_id_to_raw) |> Keyword.get(:size)
    {:reply, size, state}
  end

  #purely for testing
  def handle_call({:nbr_entries_unpacked}, _from, state) do
    size = :ets.info(state.ets_id_to_unpacked) |> Keyword.get(:size)
    {:reply, size, state}
  end
end
