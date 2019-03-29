defmodule AppUdpcanTest do
  use ExUnit.Case
  alias SignalBase.Message

  @udp_packet_count 5_000
  @local_host {127, 0, 0, 1}
  @local_port 4050

  @body :body

  doctest CanUdp
  doctest CanUdp.Server

  test "Create server" do
    {:ok, _} = CanUdp.Server.start_link({:s, self(), 4030, @local_host, 4031})
    assert GenServer.stop(:s) == :ok
  end

  test "Server connection" do
    {:ok, _} = CanUdp.Server.start_link({:s, self(), 4031, @local_host, @local_port})
    c = helper_client_start()

    Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(5, <<1, 2, 3>>))

    assert_receive {:"$gen_cast", {:raw_can_frames, [{id, payload}], :s, _}}
    assert id == 5
    assert payload == <<1, 2, 3>>

    helper_client_stop(c)
    assert GenServer.stop(:s) == :ok
  end

  test "Supervised start" do
    supervised_start()
    supervised_stop()
  end

  test "Supervised receive empty" do
    supervised_start()
    c = helper_client_start()

    # Send nonsens CAN frame
    Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(0, <<0 :: size(64)>>))

    SignalBase.publish(:sig0, [{"WiperSpeedInfo", 10}], :any)
    assert_receive {:helper_udp, _}

    helper_client_stop(c)
    supervised_stop()
  end

  test "Supervised produce UDP message via signal" do
    supervised_start()
    c = helper_client_start()

    SignalBase.publish(:sig0, [{"WiperSpeedInfo", 10}], :any)

    assert_receive {:helper_udp, data}
    assert CanUdp.parse_udp_frames(data) == [{923, <<0, 0, 0, 0, 40, 0, 0, 0>>}]

    helper_client_stop(c)
    supervised_stop()
  end

  test "Send and receive #{@udp_packet_count} UDP CAN frames" do
    supervised_start()
    c = helper_client_start()

    for _n <- 1..@udp_packet_count do
      SignalBase.publish(:sig0, [{"WiperSpeedInfo", 10}], :any)

      assert_receive {:helper_udp, data}
      assert CanUdp.parse_udp_frames(data) == [{923, <<0, 0, 0, 0, 40, 0, 0, 0>>}]
    end

    helper_client_stop(c)
    supervised_stop()
  end

  describe "Variable payload size" do
    @composed <<48, 57, 192, 100>>

    def payload_start(opts \\ []) do
      Util.Forwarder.start_link(self())

      assert {:ok, _} = SignalBase.start_link(:sig0, :any, nil)
      assert_receive :signal_base_ready
      assert {:ok, _} = CanUdp.App.start_link({
        @body,
        :sig0,
        [dbc_file: "../../configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc"] ++ opts,
        4020,
        @local_host, @local_port, "can"
      })

      # Wait for DBC files to be parsed
      assert_receive {:ready_descriptors, :sig0}
    end

    defp payload_stop() do
      assert :ok == Supervisor.stop(Payload.Name.generate_name_from_namespace(@body, :supervisor))
      assert GenServer.stop(:sig0) == :ok
      assert Util.Forwarder.terminate() == :ok
    end

    test "receive" do
      # Start
      payload_start()
      SignalBase.register_listeners(:sig0, [
        "BodyCntrForMissCom",
        "BodyCntrForMissCom_UB",
        "MstCfgIDBodyCAN",
        "MstCfgIDBodyCAN_UB",
      ], :none, self())
      c = helper_client_start(@local_port, 4020)

      # Send
      Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(1407, @composed))

      # Receive
      assert_receive {:"$gen_cast",
        {:signal, %SignalBase.Message{name_values: name_values, namespace: :any}}}

      assert Enum.sort(name_values) == [
        {"BodyCntrForMissCom", 100},
        {"BodyCntrForMissCom_UB", 1},
        {"MstCfgIDBodyCAN", 12345},
        {"MstCfgIDBodyCAN_UB", 1},
      ]

      # Stop
      helper_client_stop(c)
      payload_stop()
    end

    test "send" do
      payload_start()
      c = helper_client_start(@local_port, 4020)
      SignalBase.publish(:sig0, [
        {"BodyCntrForMissCom", 100},
        {"BodyCntrForMissCom_UB", 1},
        {"MstCfgIDBodyCAN", 12345},
        {"MstCfgIDBodyCAN_UB", 1},
      ], :none)

      assert_receive {:helper_udp, data}
      assert CanUdp.parse_udp_frames(data) == [{1407, @composed}]

      helper_client_stop(c)
      payload_stop()
    end

    test "send with fixed_payload_size: 8" do
      payload_start(fixed_payload_size: 16)
      c = helper_client_start(@local_port, 4020)
      SignalBase.publish(:sig0, [
        {"BodyCntrForMissCom", 100},
        {"BodyCntrForMissCom_UB", 1},
        {"MstCfgIDBodyCAN", 12345},
        {"MstCfgIDBodyCAN_UB", 1},
      ], :none)

      assert_receive {:helper_udp, data}
      composed_padded = <<@composed :: binary, 0 :: size(96)>>
      assert CanUdp.parse_udp_frames(data) == [{1407, composed_padded}]

      helper_client_stop(c)
      payload_stop()
    end
  end

  # Extract from human file
  # {
  # "startbit" : 48, "hs" : true, "name" : "TestSignalCntFrR", "id" : "2ef",
  # "length" : 8, "factor" : 1, "offset" : 0
  # }

  test "Send raw data via UDP and read it back from cache" do
    supervised_start()
    c = helper_client_start()
    cache_pid = Payload.Name.generate_name_from_namespace(@body, :cache)
    desc_pid = Payload.Name.generate_name_from_namespace(@body, :desc)

    # Register a listener on a signal we'll use in this test
    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())

    # Get field information
    field = Payload.Descriptions.get_field_by_name(desc_pid, "TestSignalCntFrR")
    # Assert we've gotten the right field
    assert field.name == "TestSignalCntFrR"
    assert field.id == 0x2ef
    assert field.startbit == 48

    # The cache shall say there's no stored value with this key
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]

    # Send some data via a UDP connection
    Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(field.id, <<0, 0, 0, 0, 0, 0, 250, 0>>))

    # Make sure we receive the data we just sent
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", value}]}}}
    assert value == 250

    assert_cache_decode()

    # Assert the value matches the value from the signaling system
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 250}]

    helper_client_stop(c)
    supervised_stop()
  end

  test "Try building payload with empty value" do
    supervised_start()
    desc_pid = Payload.Name.generate_name_from_namespace(@body, :desc)

    field = Payload.Descriptions.get_field_by_name(desc_pid, "TestSignalCntFrR")

    # Try encoding with real value
    Payload.Descriptions.build_payload(desc_pid, [{field, 1}])

    # Try encoding with bad value
    Payload.Descriptions.build_payload(desc_pid, [{field, :empty}])

    supervised_stop()
  end

  test "Update cache via signalbroker" do
    supervised_start()

    cache_pid = Payload.Name.generate_name_from_namespace(@body, :cache)

    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]
    assert Payload.Cache.get_nbr_entries(cache_pid) == 0

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    SignalBase.publish(:sig0, [{"TestSignalCntFrR", 210}], :any)

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", 210}]}}}
    assert_receive :cache_decoded

    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 210}]
    assert Payload.Cache.get_nbr_entries(cache_pid) == 1

    # Write a signal that doesn't exist
    SignalBase.publish(:sig0, [{"Nothing", 230}], :any)

    assert Payload.Cache.get_nbr_entries(cache_pid) == 1 # Should still be 1

    # Update 2 values and assert the cache still only has 1 entry
    SignalBase.publish(:sig0, [
      {"TestSignalCntFrR", 140},
      {"TestSignalCntFrL", 150},
    ], :any)

    assert_receive :cache_decoded
    assert Payload.Cache.get_nbr_entries(cache_pid) == 1

    # Assert values
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 140}]
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrL"]) == [{"TestSignalCntFrL", 150}]

    # Update 3 values with 1 entry that will update a new frame in the cache
    SignalBase.publish(:sig0, [
      {"TestSignalCntFrR", 40},
      {"TestSignalCntFrL", 50},
      {"SteeringAngleCR", 60},
    ], :any)

    # Two decoding operations because signals are from two different packets
    assert_receive :cache_decoded
    assert_receive :cache_decoded
    assert Payload.Cache.get_nbr_entries(cache_pid) == 2

    # Assert all published values
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 40}]
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrL"]) == [{"TestSignalCntFrL", 50}]
    assert Payload.Cache.read_channels(cache_pid, ["SteeringAngleCR"]) == [{"SteeringAngleCR", 60}]

    supervised_stop()
  end

  test "Update cache via signalbroker, make sure signals are decoded when needed" do
    supervised_start()
    cache_pid = Payload.Name.generate_name_from_namespace(@body, :cache)

    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]
    assert Payload.Cache.get_nbr_entries(cache_pid) == 0
    assert Payload.Cache.get_nbr_entries_unpacked(cache_pid) == 0

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    SignalBase.publish(:sig0, [{"TestSignalCntFrR", 210}], :any)

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", 210}]}}}

    assert_receive :cache_decoded

    # there is a listern so signal should exist unpacked
    assert Payload.Cache.get_nbr_entries_unpacked(cache_pid) == 1

    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 210}]
    assert Payload.Cache.get_nbr_entries(cache_pid) == 1

    supervised_stop()
  end

  test "Send raw data via VCAN and read it back from cache, make sure its rendered invalid in cache" do
    supervised_start()
    c = helper_client_start()
    cache_pid = Payload.Name.generate_name_from_namespace(@body, :cache)
    desc_pid = Payload.Name.generate_name_from_namespace(@body, :desc)

    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    field = Payload.Descriptions.get_field_by_name(desc_pid, "TestSignalCntFrR")
    assert field.name == "TestSignalCntFrR"
    assert field.id == 0x2ef
    assert field.startbit == 48

    assert Payload.Cache.get_nbr_entries(cache_pid) == 0
    assert Payload.Cache.get_nbr_entries_unpacked(cache_pid) == 0
    # Send raw data
    # Send some data via a UDP connection

    Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(field.id, <<0, 0, 0, 0, 0, 0, 240, 0>>))

    # Recieve value via signaling system
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", value}]}}}
    assert value == 240

    assert_cache_decode() # Give enough time to flush value tocache_pid

    # Receive value viacache_pid system. Then assert the value fromcache_pid is the
    # same as the value received from the signaling system
    assert Payload.Cache.read_channels(cache_pid, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", value}]

    # both table incache_pid should be populated
    assert Payload.Cache.get_nbr_entries(cache_pid) == 1
    assert Payload.Cache.get_nbr_entries_unpacked(cache_pid) == 1

    # remove listener
    SignalBase.remove_listener(:sig0, "TestSignalCntFrR", self())

    # Send raw data,cache_pid should be populated with id but not decoded.
    Helper.UdpClient.send_data(c, CanUdp.make_udp_frame(field.id, <<0, 0, 0, 0, 0, 0, 240, 0>>))

    assert_cache_update() # Give enough time to flush value tocache_pid
    # both id should be updated, this decoded should be purged (no listener)
    assert Payload.Cache.get_nbr_entries(cache_pid) == 1
    assert Payload.Cache.get_nbr_entries_unpacked(cache_pid) == 0

    supervised_stop()
  end

  describe "Two clients" do
    def two_start() do
      Util.Forwarder.start_link(self())

      assert {:ok, _} = SignalBase.start_link(:sig0, :any, nil)
      assert {:ok, _} = CanUdp.App.start_link({
        @body,
        :sig0,
        [human_file: "../../configuration/human_files/cfile.json"],
        4031,
        @local_host, @local_port,
        "can"
      })

      assert_receive {:ready_descriptors, :sig0}
    end

    def two_stop() do
      assert :ok == Supervisor.stop(Payload.Name.generate_name_from_namespace(@body, :supervisor))
      assert GenServer.stop(:sig0) == :ok
      assert Util.Forwarder.terminate() == :ok
    end

    # Send messages like this
    # TEST (this) -> Client #1
    # Client #1 -> Client #2
    # Client #2 -> TEST
    test "talking to each others" do
      two_start()
      SignalBase.register_listeners(:sig0, ["channel"], :none, self())
      two_stop()
    end
  end


  # INTERNAL

  # Create a suporvised `app_udpcan` instance.
  # See code for `CanUdp.App.start_link` for clarification.
  defp supervised_start() do
    Util.Forwarder.start_link(self())

    assert {:ok, _} = SignalBase.start_link(:sig0, :any, nil)
    assert {:ok, _} = CanUdp.App.start_link({
      @body,
      :sig0,
      [human_file: "../../configuration/human_files/cfile.json"],
      4031,
      @local_host, @local_port, "can"
    })

    # Wait for DBC files to be parsed
    assert_receive {:ready_descriptors, :sig0}
  end

  defp supervised_stop() do
    assert :ok == Supervisor.stop(Payload.Name.generate_name_from_namespace(@body, :supervisor))
    assert GenServer.stop(:sig0) == :ok
    assert Util.Forwarder.terminate() == :ok
  end

  # Waits for a forwarded :cache_decode via Util.Forwarder send from Payload.Cache
  defp assert_cache_decode(), do: assert_receive :cache_decoded
  defp assert_cache_update(), do: assert_receive :cache_update

  # Create a simple UDP helper client.
  # Use `helper_client_stop` to terminate.
  defp helper_client_start(listen_port \\ 4050 , dest_port \\ 4031) do
    {:ok, c} = Helper.UdpClient.start_link(listen_port, dest_port)
    c
  end

  defp helper_client_stop(pid) do
    assert GenServer.stop(pid) == :ok
  end
end
