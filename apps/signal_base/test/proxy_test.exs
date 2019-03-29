defmodule SignalServerProxyTest do
  use ExUnit.Case
  doctest SignalServerProxy

  @simple_conf %{
    broker0: %{signal_base_pid: :broker0_pid, signal_cache_pid: nil},
    broker1: %{signal_base_pid: :broker1_pid, signal_cache_pid: nil},
    broker2: %{signal_base_pid: :broker2_pid, signal_cache_pid: nil},
  }

  test "List proxy brokers from configuration" do
    {:ok, p} = SignalServerProxy.start_link({:proxy_pid, @simple_conf, :broker0})
    :ok = GenServer.stop(p)
  end

  test "List proxy brokers channels" do
    simple_initialize()

    SignalServerProxy.register_listeners(:proxy_pid, ["a"], :broker0_pid, self(), :broker0)
    SignalServerProxy.register_listeners(:proxy_pid, ["b"], :broker1_pid, self(), :broker1)
    SignalServerProxy.register_listeners(:proxy_pid, ["c"], :broker2_pid, self(), :broker2)

    channels =
      SignalServerProxy.get_channels(:proxy_pid, :all)
      |> Enum.sort()
    assert channels == ["a", "b", "c"]

    simple_terminate()
  end


  # Assert signal in different name spaces
  # Used in test below
  defp assert_for_signal(all, default, broker0, broker1, broker2) do
    assert SignalServerProxy.get_channels(:proxy_pid, :all) == all
    assert SignalServerProxy.get_channels(:proxy_pid, :default) == default
    assert SignalServerProxy.get_channels(:proxy_pid, :broker0) == broker0
    assert SignalServerProxy.get_channels(:proxy_pid, :broker1) == broker1
    assert SignalServerProxy.get_channels(:proxy_pid, :broker2) == broker2
    assert SignalServerProxy.get_channels(:proxy_pid) == default
    # this line should fail...
    # assert SignalServerProxy.get_channels(:proxy_pid, ) == default
  end

  test "Proxy register and remove" do
    simple_initialize()

    # TODO

    SignalServerProxy.register_listeners(:proxy_pid, ["a"], :broker0_pid, self(), :broker0)
    assert_for_signal(["a"], ["a"], ["a"], [], [])
    #SignalServerProxy.remove_listener(:proxy, "a", self(), :broker0)
    #assert_for_signal([], [], [], [], [])

    #SignalServerProxy.register_listener(:proxy, "a", :broker0, self(), :broker0)
    #SignalServerProxy.remove_listener(:proxy, "a", self(), :broker1)

    simple_terminate()
  end

  defp simple_initialize() do
    {:ok, _} = SignalServerProxy.start_link({:proxy_pid, @simple_conf, :broker0})
    {:ok, _} = SignalBase.start_link(:broker0_pid, :any, nil)
    {:ok, _} = SignalBase.start_link(:broker1_pid, :any, nil)
    {:ok, _} = SignalBase.start_link(:broker2_pid, :any, nil)
  end

  defp simple_terminate() do
    Helpers.close_processes([:proxy_pid, :broker0_pid, :broker1_pid, :broker2_pid])
  end
end
