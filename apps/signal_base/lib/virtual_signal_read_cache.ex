defmodule VirtualSignalReadCache do

  use GenServer;
  require Logger;

  defstruct [
    channels: nil,
  ]

  #Client

  def start_link(name, signal_base_pid) do
    GenServer.start_link(__MODULE__, signal_base_pid, name: name)
  end

  def read_channels(pid, channel_names),
    do: GenServer.call(pid, {:read_cache, channel_names})

  #purely for testing
  def get_nbr_entries(pid),
    do: GenServer.call(pid, {:nbr_entries})

  #Server
  def init(signal_base_pid) do
    table = :ets.new(SignalReadCacheTable, [:set, :private])
    # we use omnius listener, this grabs any signal
    SignalBase.register_omnius_listener(signal_base_pid, self(), self())
    {:ok, %__MODULE__{channels: table}}
  end

  def handle_cast({:signal_server_updated}, state) do
    Logger.info "signal_server_updated"
    {:noreply, state}
  end

  def handle_cast({:signal, msg}, state) do
    msg.name_values
    |> Enum.map(fn {name, value} ->
      :ets.insert(state.channels, {name, value})
    end)
    # Logger.debug ("Store #{inspect channels_with_values}, cache size is now #{inspect :ets.info(state.channels)}")
    {:noreply, state}
  end

  def handle_call({:read_cache, channel_names}, _from, state) do
    cached_values = channel_names |>
    Enum.map(fn(channel) ->
      case :ets.lookup(state.channels, channel) do
        [{channel, value}] -> {channel, value}
        [] -> {channel, :empty}
      end
    end)

    {:reply, cached_values, state}
  end

  #purely for testing
  def handle_call({:nbr_entries}, _from, state) do
    size = :ets.info(state.channels) |> Keyword.get(:size)
    {:reply, size, state}
  end
end
