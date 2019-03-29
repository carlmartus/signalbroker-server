defmodule SignalBase do
  @moduledoc """
  Recieves packets and sends them between a `SignalSwitch` and listening
  processes. Processes on the same node can register themselves as listeners on
  specified ets_db.
  """

  use GenServer;

  defstruct [
    ets_db: nil, # ETS database handle
    children: [], # Child nodes
    omnius: [],
    namespace: :empty,
    signal_cache_pid: [],
    on_change_listeners: [],
    on_subscription_change_listeners: []
  ]

  defmodule SourceListener, do: defstruct [
    pid: nil,
    source: nil,
  ]

  defmodule Message, do: defstruct [
    name_values: [],
    source: nil,
    namespace: nil,
    time_stamp: 0,
  ]

  defmodule Route, do: defstruct [
    publishers: [],
    listeners: [],
  ]

  # CLIENT

  @doc """
  Start module and register process with a name same as the module name.
  """
  def start_link(name, namespace, signal_cache_pid),
  do: GenServer.start_link(__MODULE__,
                           {namespace, signal_cache_pid},
                           name: name)

  #needed if proxy isn't used. If this is not virtual, then make sure its started by other application
  def read_values(pid, channel_names),
    do: GenServer.call(pid, {:read_cache, channel_names})

  @doc "Register own process as listener on channel `channel_name`."
  def register_listeners(pid, channel_names, source, target),
    do: GenServer.call(pid, {:register_listeners, channel_names, source, target})

  @doc "Register own process as listener on all ets_db."
  def register_omnius_listener(pid, source, target),
    do: GenServer.call(pid, {:register_omnius_listener, source, target})

  @doc "Register own process as publisher with tags on channel `channel_name`. for several signals"
  def register_publisher_with_tags(pid, channels_with_tags, target, source_listener \\ :ignore) do
    GenServer.call(pid, {:register_publisher, channels_with_tags, target, source_listener})
  end

  @doc "Register own process as publisher on channel `channel_name`. for several signals"
  def register_publisher(pid, channel_names, target) do
    # just append empty [] tags to each signal to make it fit to call, thats is [{a, [], b, []}]
    channels_with_empty_tags = Enum.zip(channel_names, Enum.map(1..Enum.count(channel_names), fn(_) -> [] end))
    GenServer.call(pid, {:register_publisher, channels_with_empty_tags, target, :ignore})
  end

  @doc """
  Remove a previously registered listener with `pid` from the channel
  `channel_name`.
  """
  def remove_listener(pid, channel_name, target),
    do: GenServer.call(pid, {:remove_listener, channel_name, target})

  @doc "Remove a previously registered listener with `pid` from all ets_db."
  def remove_listeners(pid, target),
    do: GenServer.call(pid, {:remove_listeners, target})

    #def publish(channel_name, data, time_stamp \\ System.monotonic_time()),
  def publish(pid, name_values, source, time_stamp \\ now()) do
    GenServer.call(pid, {:publish, name_values, source, time_stamp})
  end

  def now(), do: System.system_time(:microsecond)

  def get_channels(pid, on_change_listener_pid \\ :ignore), do: GenServer.call(pid, {:get_channels, on_change_listener_pid})
  def get_channels_by_tag(pid, tag, on_change_listener_pid \\ :ignore), do: GenServer.call(pid, {:get_channels_by_tag, tag, on_change_listener_pid})
  def get_children, do: GenServer.call(__MODULE__, :get_children)

  # client will should subscribe to get events when new signals are published
  def register_on_change_listener(pid, on_change_listener_pid) do
    GenServer.call(pid, {:register_on_change_listener, on_change_listener_pid})
  end

  # client will should subscribe to get events when new signals are published
  def remove_on_change_listener(pid, on_change_listener_pid) do
    GenServer.call(pid, {:remove_on_change_listener, on_change_listener_pid})
  end

  defmacro atom_and_not_nil(namespace) do
    quote do
      ((not is_nil(unquote(namespace))) and is_atom(unquote(namespace)))
    end
  end

  # SERVER
  def init({namespace, signal_cache_pid}) when (atom_and_not_nil(namespace)) do
    ets = :ets.new(ChannelTable, [:set, :private, read_concurrency: false])

    if(Util.Config.is_test(), do: Util.Forwarder.send(:signal_base_ready))

    {:ok, %__MODULE__{
      ets_db: ets,
      namespace: namespace,
      signal_cache_pid: signal_cache_pid},
    }
  end

  def handle_cast({:signal, msg}, state) do

    route_signals(state, msg.name_values, msg.source, msg.time_stamp)
    {:noreply, state}
  end

  def handle_call(:register_child, from, state) do
    {:reply, from, state}
  end

  def handle_call({:register_listeners, channel_names, source, pid}, _, state) do
    Enum.each(channel_names, fn(channel_name) ->
      add_ets_entry(channel_name, state, :listeners, {source, pid})
    end)
    notify_on_subscriptions_changed_listeners(state.ets_db, state.on_subscription_change_listeners)

    {:reply, :ok, state}
  end

  def handle_call({:register_omnius_listener, source, pid}, _, state) do
    if Enum.find(state.omnius, fn {_, x} -> x == pid end) == nil do
      {:reply, :ok, %__MODULE__{state| omnius: [{source, pid} | state.omnius]}}
    else
      {:reply, :already_registered, state}
    end
  end

  def handle_call({:register_publisher, names_with_tags, pid, source_listener}, _, state) do
    Enum.map(names_with_tags, fn({name, tags}) ->
      add_ets_entry(name, state, :publishers, {pid, tags})
    end)
    notify_on_change_listeners(state.on_change_listeners)
    state = case source_listener do
      :ignore -> state
      source_listener ->
        %__MODULE__{state | on_subscription_change_listeners: add_on_change_listener(source_listener, state.on_subscription_change_listeners)}
    end

    {:reply, :ok, state}
  end

  def handle_call({:remove_listener, name, pid}, _, state) do
    _remove_listener(name, pid, state.ets_db)
    notify_on_subscriptions_changed_listeners(state.ets_db, state.on_subscription_change_listeners)
    {:reply, :ok, state}
  end

  def handle_call({:remove_listeners, pid}, _, state) do
    collect_keys_iter(state.ets_db)
    |> Enum.map(&(_remove_listener(&1, pid, state.ets_db)))
    notify_on_subscriptions_changed_listeners(state.ets_db, state.on_subscription_change_listeners)
    {:reply, :ok, state}
  end

  def handle_call({:get_channels, on_change_listener_pid}, _, state) do
    all_keys = collect_keys_iter(state.ets_db)
    {:reply, all_keys, %__MODULE__{state | on_change_listeners: add_on_change_listener(on_change_listener_pid, state.on_change_listeners)}}
  end

  def handle_call({:get_channels_by_tag, tag, on_change_listener_pid}, _, state) do
    resp =
      collect_keys_iter(state.ets_db)
      |> Enum.reduce([], fn(name, acc) ->
        [{_, route}] = :ets.lookup(state.ets_db, name)

        case Enum.find(route.publishers, fn({_name, tags}) ->
          Enum.find(tags, &(&1 == tag))
        end) do
          nil -> acc
          _ -> [name | acc]
        end
      end)

    {:reply, resp, %__MODULE__{state | on_change_listeners: add_on_change_listener(on_change_listener_pid, state.on_change_listeners)}}
  end

  def handle_call(:get_children, _, state),
    do: {:reply, state.children, state}

  def handle_call({:register_on_change_listener, on_change_listener_pid}, _ , state) do
    {:reply, :ok, %__MODULE__{state | on_change_listeners: add_on_change_listener(on_change_listener_pid, state.on_change_listeners)}}
  end

  def handle_call({:remove_on_change_listener, on_change_listener_pid}, _ , state) do
    on_change_listener_pids = Enum.filter(state.on_change_listeners, fn(x) -> x != on_change_listener_pid end)
    {:reply, :ok, %__MODULE__{state | on_change_listeners: on_change_listener_pids}}
  end

  def handle_call({:publish, name_values, source, time_stamp}, _, state) do
    reply = route_signals(state, name_values, source, time_stamp)

    if(Util.Config.is_test(), do: Util.Forwarder.send(:signal_base_published))
    {:reply, reply, state}
  end


  # INTERNAL

  defp notify_on_subscriptions_changed_listeners(ets_db, on_subscription_change_listeners) do
    Enum.each(on_subscription_change_listeners, fn(%SourceListener{pid: p, source: s}) ->
      signals = get_signals_with_listeners(s, ets_db)
      GenServer.cast(p, {:signal_server_subscriptions_updated, signals})
    end)
  end

  defp notify_on_change_listeners(listeners) do
    Enum.map(listeners, fn(listener) -> GenServer.cast(listener, {:signal_server_updated}) end)
  end

  defp add_on_change_listener(on_change_listener_pid, on_change_listeners) do
    case on_change_listener_pid do
      :ignore -> on_change_listeners
      _ ->
        case Enum.member?(on_change_listeners, on_change_listener_pid) do
          true -> on_change_listeners
          _ -> [on_change_listener_pid | on_change_listeners]
        end
    end
  end

  defp ets_get_and_update(ets, name, cb) do
    value = case :ets.lookup(ets, name) do
      [] -> %Route{}
      [{_, existing}] -> existing
    end

    :ets.insert(ets, {name, cb.(value)})
  end

  defp add_ets_entry(channel_name, state, field, target) do
    ets_get_and_update(state.ets_db, channel_name, fn value ->
      list = Map.get(value, field)

      new_list = list ++ [target]
      Map.put(value, field, new_list)
    end)
  end

  defp _remove_listener(name, pid, ets) do
    ets_get_and_update(ets, name, fn value ->
      list = Map.get(value, :listeners)
      new_list = Enum.filter(list, fn {_, p} -> p != pid end)
      Map.put(value, :listeners, new_list)
    end)
  end

  defp collect_keys_iter(ets), do: collect_keys_iter(ets, :ets.first(ets))
  defp collect_keys_iter(_, :'$end_of_table'), do: []
  defp collect_keys_iter(ets, current) do
    [current] ++ collect_keys_iter(ets, :ets.next(ets, current))
  end

  defp route_messages([], _namespace, _signals_with_value, _source, _time_stamp), do: :ok
  defp route_messages(targets, namespace, name_values, source, time_stamp) do
    targets
    |> Enum.filter(fn {target_source, _} ->
      target_source != source
    end)
    |> Enum.map(fn {_, target_pid} ->
      msg = %Message{
        name_values: name_values,
        source: source,
        namespace: namespace,
        time_stamp: time_stamp,
      }

      #GenServer.cast(target_pid, {:signal, name_values, source, time_stamp})
      GenServer.cast(target_pid, {:signal, msg})
    end)
  end

  # to test this thingy
  # Enum.count(GenServer.call(:signal_base_pid, {:get_signals_with_listeners, :vcan1_conn}))

  defp get_signals_with_listeners(source, ets_db) do
    all_signals = collect_keys_iter(ets_db)
    Enum.filter(all_signals, fn(signal) ->
      [{_, targets}] = :ets.lookup(ets_db, signal)
      # Enum.member?(Keyword.keys(targets.listeners), source) == false
      case Enum.filter(Keyword.keys(targets.listeners), &(&1 != source)) do
        [] -> false
        _ -> true
      end
    end)
  end

  #@doc """
  #  convert %{channel_name => [pid1, pid2]} to
  #  %{pid1 => [{"channel_name", value}], pid2 => [{"channel_name", value}]}
  #"""
  defp get_map_for_signal(state, {channel_name, _value} = signal) do
    case :ets.lookup(state.ets_db, channel_name) do
      [] -> %{}
      [{_, targets}] ->
        Enum.reduce(targets.listeners, %{}, fn(listener, acc) ->
          Map.put(acc, listener, [signal])
        end)
    end
  end


  defp route_signals(state, route_signals, source, time_stamp) do
    Counter.tick_signal(length(route_signals))

    route_messages(state.omnius, state.namespace,
                   route_signals, source, time_stamp)

    # merge
    # %{pid1 => [{"channel_name", value}], pid2 => [{"channel_name", value"}]}
    # %{pid1 => [{"channel_name1", value1}], pid3 => [{"channel_name2", value2"}]}
    # ...
    # to
    # %{pid1 => [{"channel_name", value}, {"channel_name1", value1}], pid2 => [{"channel_name", value"}], pid3 => [{"channel_name2", value2"}]}

    pid_to_channels_with_values = Enum.reduce(route_signals, %{}, fn(signal, acc) ->
      map = get_map_for_signal(state, signal)
      Map.merge(map, acc, fn(_k, v1, v2) -> v1 ++ v2 end)
    end)

    for {pid, channels_with_data} <- pid_to_channels_with_values do
      route_messages([pid], state.namespace,
                     channels_with_data, source, time_stamp)
    end
  end
end
