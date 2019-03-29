defmodule SignalServerProxy do
  @moduledoc """
  Proxy interface to reach the intended `SignalBase`.

  Reads the configuration file to get the pids of all available brokers
  (`SignalBase`).

  Several methods in this module accept a namespace argument. Use this argument
  to specify which signal broker(s) to access.

  # Name spaces
  The default namespace is `:default`, meaning it will send to the default
  broker from the configuration file.

  The name space `:all` means that the broker will send to all brokers.
  Consequenty, some brokers might not have the signal they are being asked to
  handle. In this case, that broker will do nothing.
  """

  use GenServer;

  defmodule State, do: defstruct [
    ets_db: nil, # ETS database handle
    all_broker_pids: [],
    proxy_config: nil,
    default_namespace: "",
  ]


  defmacro atom_and_not_nil(namespace) do
    quote do
      ((not is_nil(unquote(namespace))) and is_atom(unquote(namespace)))
    end
  end

  # Client

  def start_link({name, proxy_config, default_namespace}) do
    GenServer.start_link(
      __MODULE__,
      {proxy_config, default_namespace},
      name: name)
  end

  @doc "Remove listener of channel from namespace(s)"
  def remove_listener(pid, channel_name, target, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:remove_listener, channel_name, target, namespace})

  @doc "Remove listener from all brokers."
  def remove_listeners(pid, target),
    do: GenServer.call(pid, {:remove_listeners, target})

  # TODO Should this be implemented as cast?
  def publish(pid, name_values, source, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:publish, name_values, source, namespace})

  def get_default_namespace(pid),
    do: GenServer.call(pid, :get_default_namespace)

  @doc """
  Get all available channels that have either a listener or publisher
  registered to it.
  """

  # Server

  def get_configuration(pid),
    do: GenServer.call(pid, {:get_configuration})

  def get_channels(pid, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:get_channels, :ignore, namespace})

  def get_channels_by_tag(pid, tag, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:get_channels_by_tag, tag, :ignore, namespace})

  def get_channels_tree(pid, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:get_channels_tree, namespace})


  def get_channels_and_listen_for_events(pid, event_listener_pid, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:get_channels, event_listener_pid, namespace})

  def get_channels_by_tag_and_listen_for_events(pid, tag, event_listener_pid, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:get_channels_by_tag, tag, event_listener_pid, namespace})


  def register_listeners(pid, channel_names, source, target, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:register_listeners, channel_names, source, target, namespace})

  def register_omnius_listener(pid, source, target, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:register_omnius_listener, source, target, namespace})

  def register_publisher(pid, channel_names, target, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:register_publisher, channel_names, target, namespace})

  def read_values(pid, channel_names, namespace \\ :default)
  when (atom_and_not_nil(namespace)),
    do: GenServer.call(pid, {:read_cache, channel_names, namespace})

  def init({proxy_config, default_namespace}) when (atom_and_not_nil(default_namespace)) do
    ets = :ets.new(ProxyTable, [:set, :private, read_concurrency: false])

    all_broker_pids =
      proxy_config
      |> Map.values()
      |> Enum.map(fn(config) ->
        config.signal_base_pid
      end)

    if(Util.Config.is_test(), do: Util.Forwarder.send(:signal_proxy_ready))

    default_configured = Map.get(proxy_config, default_namespace)

    error = "ERROR default namespace `#{inspect default_namespace}` incorrectly configured. Fix your interfaces.json"
    case default_configured do
      nil -> Util.Config.app_log(error)
        throw(error)
      something -> :ok
    end

    state = %State{
      ets_db: ets,
      proxy_config: proxy_config,
      default_namespace: default_namespace,
      all_broker_pids: all_broker_pids,
    }

    {:ok, state}
  end


  def handle_call({:get_configuration}, _, state) do
    config_info =
      Enum.reduce(state.proxy_config, %{}, fn({namespace, %{type: type}}, acc) ->
        Map.put(acc, namespace, %{type: type})
      end)
    {:reply, config_info, state}
  end

  def handle_call({:get_channels, event_listener_pid, namespace}, _, state) do
    all_keys =
      flatmap_intended_broker(state, namespace, fn(pid) ->
        SignalBase.get_channels(pid, event_listener_pid)
      end)
      |> Enum.uniq()

    {:reply, all_keys, state}
  end

  def handle_call({:get_channels_by_tag, tag, event_listener_pid, namespace}, _, state) do
    all_keys =
      flatmap_intended_broker(state, namespace, fn(pid) ->
        SignalBase.get_channels_by_tag(pid, tag, event_listener_pid)
      end)
      |> Enum.uniq()

    {:reply, all_keys, state}
  end

  def handle_call({:get_channels_tree, namespace}, _, state) do
    signal_tree =
      flatmap_intended_broker(state, namespace, fn(pid) ->
        #this hidden magic is not pretty
        entry = Map.get(state.proxy_config, namespace)
        case entry.type == "virtual" do
          true -> []
          _ ->
            desc_pid = Payload.Name.generate_name_from_namespace(namespace, :desc)
            GenServer.call(desc_pid, {:get_all_names_tree})
        end
      end)

    case signal_tree do
      signals -> {:reply, signals, state}
      _ -> {:reply, [], state}
    end

  end

  def handle_call({:publish, name_values, source, namespace}, _, state) do
    replies = flatmap_intended_broker(state, namespace, fn(sig_pid) ->
      SignalBase.publish(sig_pid, name_values, source)
    end)

    {:reply, replies, state}
  end

  def handle_call(:get_default_namespace, _, state) do
    {:reply, state.default_namespace, state}
  end

  def handle_call({:register_listeners, channel_names, source, pid, namespace}, _, state) do
    map_intended_broker(state, namespace, fn(sig_pid) ->
      SignalBase.register_listeners(sig_pid, channel_names, source, pid)
    end)

    {:reply, :ok, state}
  end

  def handle_call({:register_omnius_listener, source, pid, namespace}, _, state) do
    response = map_intended_broker(state, namespace, fn(sig_pid) ->
      SignalBase.register_omnius_listener(sig_pid, source, pid)
    end)

    {:reply, response, state}
  end

  def handle_call({:register_publisher, names, pid, namespace}, _, state) do
    map_intended_broker(state, namespace, fn(sig_pid) ->
      SignalBase.register_publisher(sig_pid, names, pid)
    end)

    {:reply, :ok, state}
  end


  def handle_call({:remove_listener, name, pid, namespace}, _, state) do
    map_intended_broker(state, namespace, fn(sig_pid) ->
      SignalBase.remove_listener(sig_pid, name, pid)
    end)

    {:reply, :ok, state}
  end

  # TODO this implementation is a lite rude, producing unnecessary calls to some namespaces
  def handle_call({:remove_listeners, pid}, _, state) do
    map_intended_broker(state, :all, fn(sig_pid) ->
      SignalBase.remove_listeners(sig_pid, pid)
    end)

    {:reply, :ok, state}
  end

  def handle_call({:read_cache, channel_names, namespace}, _, state)
  when namespace != :all do # Can't be applied to namespace :all

    field = Map.get(state.proxy_config, namespace)

    res = case field do
      nil -> read_values_local(
        Map.get(state.proxy_config, state.default_namespace).signal_cache_pid,
        channel_names)
      field -> read_values_local(field.signal_cache_pid, channel_names)
    end

    {:reply, res, state}
  end

  # TODO: this could en up in virtual or real cache, should be redone with protocols
  defp read_values_local(pid, channel_names),
    do: GenServer.call(pid, {:read_cache, channel_names})

  defp get_intended_broker_core(state, namespace) do
    case Map.get(state.proxy_config, namespace) do
      nil -> nil
      a -> a.signal_base_pid
    end
  end

  defp get_intended_broker(state, :default), do: [
    Map.get(state.proxy_config, state.default_namespace).signal_base_pid]
  defp get_intended_broker(state, :all), do: state.all_broker_pids
  defp get_intended_broker(state, nil), do: state.all_broker_pids
  defp get_intended_broker(state, namespaces) when is_list(namespaces) do
    Enum.map(namespaces, fn(x) -> get_intended_broker_core(state, x) end)
  end
  defp get_intended_broker(state, namespace) do
    [get_intended_broker_core(state, namespace)]
  end

  defp map_intended_broker(state, namespace, cb) do
    Enum.filter(get_intended_broker(state, namespace), fn(x) -> x != nil end)
    |> Enum.map(cb)
  end

  defp flatmap_intended_broker(state, namespace, cb) do
    Enum.filter(get_intended_broker(state, namespace), fn(x) -> x != nil end)
    |> Enum.flat_map(cb)
  end
end
