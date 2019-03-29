defmodule SignalBaseTest do
  use ExUnit.Case
  doctest SignalBase
  require Logger
  alias SignalBase.Message

  @signal_count 500


  # TESTS

  test "Register many signals" do
    {:ok, p} = SignalBase.start_link(:s, :any, nil)
    Helpers.close_process(p)
  end


  test "SignalCatcher helper test" do
    {:ok, p} = Helper.SignalCatcher.start_link()
    assert GenServer.call(p, :get_state) == nil
    assert GenServer.call(p, :get_counter) == 0
    assert GenServer.call(p, :test) == :ok
    assert GenServer.call(p, :get_state) == :test
    assert GenServer.call(p, :get_counter) == 1
    Helpers.close_process(p)
  end

  test "Send and reveive 1 signal" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    SignalBase.register_listeners(:s, ["TestChannel"], :none, sc)
    assert GenServer.call(sc, :get_state) == nil
    assert GenServer.call(sc, :get_counter) == 0

    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert {:signal, msg} = GenServer.call(sc, :get_state)
    assert msg.name_values == [{"TestChannel", :message}]
    assert msg.source == :any

    Helpers.close_processes([sb, sc])
  end

  test "Receive notification once signal base is updated" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    {:ok, sc2} = Helper.SignalCatcher.start_link()

    assert SignalBase.get_channels(:s, sc) == []
    assert SignalBase.get_channels(:s, sc2) == []
    assert GenServer.call(sc, :get_counter) == 0
    assert GenServer.call(sc2, :get_counter) == 0

    SignalBase.register_publisher(:s, ["TestChannel1"], sc)
    SignalBase.register_publisher(:s, [{"TestChannel2", :tag2}, "TestChannel3"], sc2)

    assert GenServer.call(sc, :get_counter) == 2
    assert GenServer.call(sc2, :get_counter) == 2
    assert GenServer.call(sc, :get_state) == {:signal_server_updated}
    assert GenServer.call(sc2, :get_state) == {:signal_server_updated}
    assert Enum.sort(SignalBase.get_channels(:s, sc)) == Enum.sort(["TestChannel1", {"TestChannel2", :tag2}, "TestChannel3"])
    assert Enum.sort(SignalBase.get_channels(:s, sc2)) == Enum.sort(["TestChannel1", {"TestChannel2", :tag2}, "TestChannel3"])

    Helpers.close_processes([sb, sc, sc2])
  end

  test "Receive notification once signal base is updated, manual subscription" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()

    assert SignalBase.get_channels(:s) == []
    assert GenServer.call(sc, :get_counter) == 0

    SignalBase.register_publisher(:s, ["TestChannel1"], sc)
    assert GenServer.call(sc, :get_counter) == 0

    # manual register
    SignalBase.register_on_change_listener(:s, sc)
    SignalBase.register_publisher(:s, ["TestChannel1"], sc)
    assert GenServer.call(sc, :get_counter) == 1

    #unregister make sure we don't receive updates

    SignalBase.remove_on_change_listener(:s, sc)
    SignalBase.register_publisher(:s, ["TestChannel1"], sc)
    assert GenServer.call(sc, :get_counter) == 1


    Helpers.close_processes([sb, sc])
  end

  test "Send and receive #{inspect @signal_count} messages" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    SignalBase.register_listeners(:s, ["TestChannel"], :none, sc)

    for n <- 1..@signal_count do
      SignalBase.publish(:s, [{"TestChannel", n}], :any)
    end
    wait_sync(:s)

    assert GenServer.call(sc, :get_counter) == @signal_count

    Helpers.close_processes([sb, sc])
  end

  test "#{@signal_count} listeners and publishers" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    register_sync_listener(:s)

    # Create listeners and register them
    scs = for n <- 1..@signal_count do

      # Create
      {:ok, sc} = Helper.SignalCatcher.start_link()

      # Register
      SignalBase.register_listeners(:s, [n], :none, sc)

      {n, sc}
    end

    wait_sync(:s)

    # Send messages
    for {n, sc} <- scs do
      GenServer.cast(sc, {:execute, fn ->
        SignalBase.publish(:s, [{n, n}], :any)
      end})

      wait_sync(:s)
    end

    wait_sync(:s)
    :timer.sleep(10)

    # Assert everyone recieved their message
    for {n, sc} <- scs do
      assert GenServer.call(sc, :get_counter) == 1
      assert {:signal, msg} = GenServer.call(sc, :get_state)
      assert msg.name_values == [{n, n}]
      assert msg.source == :any
    end

    scs |> Enum.map(fn {_n, pid} -> pid end) |> Helpers.close_processes()
    Helpers.close_process(sb)
  end

  # test "Register omnius listener" do
  #   {:ok, sb} = SignalBase.start_link(:s, :any, nil)
  #   assert SignalBase.register_omnius_listener(:s, :none, "test_a") == :ok
  #   assert SignalBase.register_omnius_listener(:s, :none, "test_b") == :ok
  #   assert SignalBase.register_omnius_listener(:s, :none, "test_a") == :already_registered
  #   assert SignalBase.register_omnius_listener(:s, :none, "test_b") == :already_registered
  #   Helpers.close_process(sb)
  # end

  # omnius listener is not supported, redesign this test or remove
  # test "Receive omnius listener message" do
  #   {:ok, sb} = SignalBase.start_link(:s, :any, nil)
  #   {:ok, sc} = Helper.SignalCatcher.start_link
  #
  #   SignalBase.publish(:s, [{"test", :something}], :any)
  #   assert GenServer.call(sc, :get_counter) == 0
  #
  #   SignalBase.register_omnius_listener(:s, :none, sc)
  #
  #   SignalBase.publish(:s, [{"test", :something}], :any)
  #   assert 1 = GenServer.call(sc, :get_counter)
  #   assert {:signal, msg} = GenServer.call(sc, :get_state)
  #   assert msg.name_values == [{"test", :something}]
  #   assert msg.source == :any
  #
  #   Helpers.close_processes([sb, sc])
  # end

  test "Unregister 1 listener" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    SignalBase.register_listeners(:s, ["TestChannel"], :none, sc)

    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert GenServer.call(sc, :get_counter) == 1

    SignalBase.remove_listener(:s, "TestChannel", sc)
    wait_sync(:s)

    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert GenServer.call(sc, :get_counter) == 1

    Helpers.close_processes([sb, sc])
  end

  test "Unregister all listeners" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    SignalBase.register_listeners(:s, ["TestChannel"], :none, sc)
    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert GenServer.call(sc, :get_counter) == 1

    SignalBase.remove_listeners(:s, sc)
    wait_sync(:s)

    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert GenServer.call(sc, :get_counter) == 1

    Helpers.close_processes([sb, sc])
  end

  test "Time stamp" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    SignalBase.register_listeners(:s, ["TestChannel"], :none, sc)
    wait_sync(:s)

    # Send with automatic time stamp
    SignalBase.publish(:s, [{"TestChannel", :message}], :any)
    wait_sync(:s)

    assert {:signal, msg} = GenServer.call(sc, :get_state)
    assert msg.name_values == [{"TestChannel", :message}]
    assert msg.source == :any

    time_stamp = SignalBase.now()
    SignalBase.publish(:s, [{"TestChannel", :message}], :any, time_stamp)
    wait_sync(:s)

    assert {:signal, msg} = GenServer.call(sc, :get_state)
    assert msg.name_values == [{"TestChannel", :message}]
    assert msg.source == :any
    assert msg.time_stamp == time_stamp

    Helpers.close_processes([sb, sc])
  end

  @doc "SignalBase shouldn't send messages back to the source of the message"
  test "Blocked source" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    wait_sync(:s)
    assert GenServer.call(sc, :get_counter) == 0

    SignalBase.register_publisher(:s, ["TestChannel"], sc)
    SignalBase.register_listeners(:s, ["TestChannel"], :source1, sc)

    wait_sync(:s)
    assert GenServer.call(sc, :get_counter) == 0

    # Test this segment a few times
    for n <- 0..@signal_count do

      # Send message to be blocked. Because of :source1 as source
      SignalBase.publish(:s, [{"TestChannel", :message}], :source1)

      assert GenServer.call(sc, :get_counter) == n

      # Send message to be recieved. Because of :source2 as source
      SignalBase.publish(:s, [{"TestChannel", :message}], :source2)

      assert GenServer.call(sc, :get_counter) == n+1
      assert {:signal, msg} = GenServer.call(sc, :get_state)
      assert msg.name_values == [{"TestChannel", :message}]
      assert msg.source == :source2
    end

    Helpers.close_processes([sb, sc])
  end

  @doc "Make sure we are able to send mulitple messages in same request"
  test "Blocked source, several listeners" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, sc1} = Helper.SignalCatcher.start_link()
    {:ok, sc2} = Helper.SignalCatcher.start_link()
    register_sync_listener(:s)

    wait_sync(:s)
    assert GenServer.call(sc1, :get_counter) == 0
    assert GenServer.call(sc2, :get_counter) == 0

    # SignalBase.register_publisher("TestChannel", sc)
    SignalBase.register_listeners(:s, ["TestChannel"], :sc1, sc1)
    SignalBase.register_listeners(:s, ["TestChannel_B"], :sc1, sc1)

    SignalBase.register_listeners(:s, ["TestChannel"], :sc2, sc2)

    wait_sync(:s)
    assert GenServer.call(sc1, :get_counter) == 0
    assert GenServer.call(sc2, :get_counter) == 0

    # Test this segment a few times
    for n <- 0..@signal_count do

      # message should be recived by sc2 only
      SignalBase.publish(:s, [{"TestChannel", :message}, {"TestChannel_B", :message2}], :sc1)

      assert GenServer.call(sc1, :get_counter) == 0

      assert GenServer.call(sc2, :get_counter) == n+1
      assert {:signal, msg} = GenServer.call(sc2, :get_state)
      assert msg.name_values == [{"TestChannel", :message}]
      assert msg.source == :sc1
    end


    GenServer.call(sc1, :reset_counter)
    GenServer.call(sc2, :reset_counter)
    # Test this segment a few times
    for n <- 0..@signal_count do

      # message should be recived by sc1 and sc2 since its dispatched from :sc3
      SignalBase.publish(:s, [{"TestChannel", :message}, {"TestChannel_B", :message2}], :sc3)

      assert GenServer.call(sc1, :get_counter) == n+1
      expected_payload = [{"TestChannel", :message}, {"TestChannel_B", :message2}]
      # order of messages is irrelavant
      assert {:signal, msg} = GenServer.call(sc1, :get_state)
      assert msg.source == :sc3

      received_payload = msg.name_values
      assert Enum.sort(expected_payload) == Enum.sort(received_payload)


      assert GenServer.call(sc2, :get_counter) == n+1
      assert {:signal, msg} = GenServer.call(sc2, :get_state)
      assert msg.name_values == [{"TestChannel", :message}]
      assert msg.source == :sc3
    end

    Helpers.close_processes([sb, sc1, sc2])
  end

  test "Write and read from cache" do
    {:ok, sb} = SignalBase.start_link(:s, :any, :c)
    {:ok, signalreadcache} = VirtualSignalReadCache.start_link(:c, :s)
    register_sync_listener(:s)

    values = ["hejsan", "hoppsan"]

    result = SignalBase.read_values(:c, values)
    expected_result = [{"hejsan", :empty}, {"hoppsan", :empty}]

    assert Enum.sort(expected_result) == Enum.sort(result)

    #note publish is cast(async), read is call(sync)
    SignalBase.register_publisher(:s, values, :s)
    SignalBase.publish(:s, [{"hejsan", 15}], :sc1)
    SignalBase.publish(:s, [{"hejsan", 12}], :sc1)
    wait_sync(:s)

    result = SignalBase.read_values(:c, values)
    expected_result = [{"hejsan", 12}, {"hoppsan", :empty}]

    wait_sync(:s)
    assert Enum.sort(expected_result) == Enum.sort(result)

    Helpers.close_processes([sb, signalreadcache])
  end

  test "Size of case doesn't grow" do
    {:ok, sb} = SignalBase.start_link(:s, :any, nil)
    {:ok, signalreadcache} = VirtualSignalReadCache.start_link(:c, :s)
    register_sync_listener(:s)

    for n <- 0..@signal_count do
      name1 = "hejsan" <> Integer.to_string(n)
      name2 = "hoppsan" <> Integer.to_string(n)
      values = [{name1, n}, {name2, n}]
      SignalBase.register_publisher(:s, [name1, name2], :s)

      SignalBase.publish(:s, values, :sc1)

      wait_sync(:s)

      assert VirtualSignalReadCache.get_nbr_entries(:c) == ((n+1) * 2 + 1)

      #publish again
      SignalBase.publish(:s, values, :sc1)
      wait_sync(:s)

      SignalBase.read_values(:c, values)
      assert VirtualSignalReadCache.get_nbr_entries(:c) == ((n+1) * 2 + 1)
    end

    Helpers.close_processes([sb, signalreadcache])
  end

  defp register_sync_listener(sig_pid) do
    SignalBase.register_listeners(sig_pid, ["sig_sync"], :none, self())
  end

  # Blocks until a message gets passed through a signal base
  defp wait_sync(sig_pid) do
    SignalBase.publish(sig_pid, [{"sig_sync", -2}], :any)
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"sig_sync", -2}]}}}
  end
end
