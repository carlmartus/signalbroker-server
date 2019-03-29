defmodule UnixDSTest do
  use ExUnit.Case
  alias SignalBase.Message
  @broker_count 2

  test "Init and terminate" do
    start()
    run_external_client(1)
    stop()
  end

  test "Init, 3X sync and terminate" do
    start()
    run_external_client(11)
    wait_sync()
    wait_sync()
    wait_sync()
    stop()
  end

  test "Client send signal" do
    start()
    SignalServerProxy.register_listeners(:test_way, ["simple"], :test_source, self(), :all)
    run_external_client(2)

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"simple", -5}]}}}

    stop()
  end

  test "Client send signal and blocked by source" do
    start()
    SignalServerProxy.register_listeners(:test_way, ["simple"], :testspace, self(), :all)
    run_external_client(2)
    #refute_receive {:"$gen_cast", {:signal, [{"simple", 1.0}], _, _}}
    refute_receive {:"$gen_cast", {:signal, %Message{name_values: [{"simple", -5}]}}}

    stop()
  end

  test "Client send wakeup signal and blocked by source" do
    start()
    SignalServerProxy.register_listeners(:test_way, ["HusLin18Fr01"], :testspace, self(), :all)
    run_external_client(18)
    #refute_receive {:"$gen_cast", {:signal, [{"simple", 1.0}], _, _}}
    refute_receive {:"$gen_cast", {:signal, %Message{name_values: [{"HusLin18Fr01", :arbitration}]}}}

    stop()
  end



  test "Null-source handshake" do
    start()
    SignalServerProxy.register_listeners(:test_way, ["simple"], :test_source, self(), :all)
    run_external_client(3)
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"simple", 1.0}], source: source}}}

    assert(source |> Atom.to_string() |> String.match?(~r/unixds_\d+/))

    stop()
  end

  test "Send to #{@broker_count+1} different brokers" do
    start()

    for n <- 0..@broker_count do
      name_sb = broker_pid(n)
      name_signal = "simple#{n}"

      SignalServerProxy.register_publisher(:test_way, [name_signal], :irrelavant, name_sb)
      SignalServerProxy.register_listeners(
        :test_way, [name_signal], :test_source, self(), name_sb)
    end

    run_external_client(4)

    for n <- 0..@broker_count do
      name_signal = "simple#{n}"
      #assert_receive {:"$gen_cast", {:signal, [{^name_signal, _}], _, _}}
      assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{^name_signal, _}]}}}
    end

    stop()
  end

  test "Read from #{@broker_count+1} different brokers" do
    start()

    for n <- 0..@broker_count do
      name_sb = broker_pid(n)
      name_signal = "simple#{n}"
      SignalServerProxy.register_publisher(:test_way, [name_signal], :irrelavant, name_sb)
      SignalServerProxy.register_listeners(
        :test_way, [name_signal], :test_source, self(), name_sb)

      SignalServerProxy.publish(
        :test_way, [{name_signal, n/1}], :test_source, name_sb)

      assert_receive :signal_base_published
    end

    run_external_client(5)
    wait_sync();

    for n <- 0..@broker_count do
      name_signal = "simple#{n}"
      #assert_receive {:"$gen_cast", {:signal, [{^name_signal, value}], _, _}}
      assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{^name_signal, value}]}}}
      assert_in_delta value, (n+1), 0.0001
    end

    stop()
  end

  test "Subscribe and signal from #{@broker_count+1} different brokers" do
    start()

    for n <- 0..@broker_count do
      SignalServerProxy.register_listeners(
        :test_way, ["simple"], :test_source, self(),
        broker_pid(n))
    end

    run_external_client(6)
    wait_sync();
    :timer.sleep(5)

    for n <- 0..@broker_count do
      SignalServerProxy.publish(
        :test_way, [{"simple", n}],
        :test_source, broker_pid(n))

      assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{_, value}]}}}
      assert_in_delta value, n, 0.0001
    end

    wait_sync();
    stop()
  end

  test "Read signal that doesn't exist" do
    start()
    run_external_client(7)
    stop()
  end

  describe "Timeout" do
    test "set" do
      start()
      run_external_client(8)

      stop()
    end

    test "trigger" do
      start()
      SignalServerProxy.register_listeners(:test_way, ["OK"], :test_source, self(), :all)

      run_external_client(9)

      # Get message within 300 milliseconds
      assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"OK", 0}]}}}, 300
      stop()
    end
  end


  # ====
  # UTIL
  # ====

  test "Read from several namespaces" do
    start()

    data = [
      {:broker2, "a", 1},
      {:broker0, "b", 2},
      {:broker1, "c", 3},
      {:broker1, "d", 4},
      {:broker2, "e", 5},
      {:broker0, "f", 6},
    ]

    Enum.map(data, fn({namespace, channel, value}) ->
      SignalServerProxy.publish(
        :test_way, [{channel, value}], :test_source, namespace)
    end)

    run_external_client(8)
    stop()
  end

  test "Omitted namespace" do
    start()
    run_external_client(12)
    wait_sync()

    assert SignalServerProxy.read_values(:test_way, ["a"], :broker0) == [{"a", 1}]
    assert SignalServerProxy.read_values(:test_way, ["b"], :broker1) == [{"b", 2}]
    assert SignalServerProxy.read_values(:test_way, ["c"], :broker2) == [{"c", 3}]

    stop()
  end

  describe "LIN" do
    defp lin_start() do
      start()
      assert {:ok, _} = Util.Config.start_link("config/test_lin1.json")
    end

    defp lin_stop() do
      stop()
      assert GenServer.stop(Util.Config) == :ok
    end

    test "list busses" do
      lin_start()
      run_external_client(13)
      lin_stop()
    end

    test "list schedules" do
      lin_start()
      run_external_client(14)
      lin_stop()
    end

    test "set scheduler" do
      lin_start()
      run_external_client(15)
      assert_receive {:lin_scheduler_set, "CcmLin18ScheduleTable1", 2}
      lin_stop()
    end

    test "start scheduler" do
      lin_start()
      run_external_client(16)
      assert_receive :lin_start
      lin_stop()
    end

    test "stop scheduler" do
      lin_start()
      run_external_client(17)
      assert_receive :lin_stop
      lin_stop()
    end
  end

  defp start() do
    Util.Forwarder.start_link(self())
    conf = Enum.reduce(0..@broker_count, %{}, fn(n, acc) ->
      name_sb = broker_pid(n)
      name_cache = cache_pid(n)
      acc = Map.put(acc, name_sb, %{
        signal_base_pid: name_sb,
        signal_cache_pid: name_cache,
      })

      # Pid is same as namespace
      {:ok, _} = SignalBase.start_link(name_sb, name_sb, name_cache)
      {:ok, _} = VirtualSignalReadCache.start_link(name_cache, name_sb)

      assert_receive :signal_base_ready
      acc
    end)
    #conf = %{
    #broker0: %{signal_base_pid: :broker0, signal_cache_pid: nil},
    #broker1: %{signal_base_pid: :broker1, signal_cache_pid: nil},
    #broker2: %{signal_base_pid: :broker2, signal_cache_pid: nil},
    #}

    {:ok, _} = UnixDS.ClientHolder.start_link(:client_holder)
    {:ok, _} = UnixDS.Server.start_link({:server, :client_holder, "/tmp/signalserver/cs-unix", :test_way})

    #{:ok, _} = SignalBase.start_link(broker_pid(0), :any, nil)
    {:ok, _} = SignalServerProxy.start_link({:test_way, conf, :broker0})

    SignalServerProxy.register_listeners(:test_way, ["sig_sync"], :test_source, self(), :broker2)
    SignalServerProxy.register_publisher(:test_way, ["sig_sync"], :test_source, :broker2)
    :ok
  end

  defp stop() do
    wait_external_client()

    assert GenServer.stop(:client_holder) == :ok
    #assert GenServer.stop(:server) == :ok # Can't shut it down :(
    assert GenServer.stop(:test_way) == :ok

    for n <- 0..@broker_count do
      assert GenServer.stop(broker_pid(n)) == :ok
      assert GenServer.stop(cache_pid(n)) == :ok
    end
    #assert GenServer.stop(broker_pid(0)) == :ok

    assert Util.Forwarder.terminate() == :ok
  end

  defp broker_pid(n), do: String.to_atom("broker#{n}")
  defp cache_pid(n), do: String.to_atom("cache#{n}")

  defp run_external_client(num) do
    :timer.sleep(10)

    send_to = self()
    spawn fn() ->
      dir = :code.priv_dir(:app_unixds)
      program = "#{dir}/testunit"
      {_, code} = System.cmd(program, ["-u#{num}"])
      #System.cmd("valgrind", [program, "-u#{num}"])

      if code == 0 do
        send(send_to, :program_done)
      end
    end
    :timer.sleep(10)
  end

  defp wait_external_client() do
    assert_receive :program_done
  end

  defp wait_sync() do
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"sig_sync", -2}]}}}

    :timer.sleep(10)
    SignalServerProxy.publish(:test_way, [{"sig_sync", -3}], :test_source, :broker2)
  end
end
