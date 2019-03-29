defmodule AppNgCanTest do
  use ExUnit.Case
  alias SignalBase.Message

  # TESTS

  test "Setup" do
    setup()

    {:ok, p} = AppNgCan.start_link({
      {"vcan0", :desc, :conn, :signal, :writer, :cache, :sig0, String.to_atom("chassis"), "can"},
      human_file: "../../configuration/human_files/cfile.json"})

    assert SignalBase.get_channels(:sig0) != []

    assert GenServer.stop(p) == :ok
    clean_up()
  end

  test "Load human json" do
    setup_scenario1()

    wiper = Payload.Descriptions.get_field_by_name(:desc, "WiperSpeedInfo")
    assert wiper.name == "WiperSpeedInfo"
    assert wiper.id == 923

    teardown_scenario1()
  end

  test "Check if we are able to catch diagnostics frames" do
    setup_scenario1()

    diag_frame = Payload.Descriptions.get_field_by_name(:desc2, "CemToPdmBodyDiagReqFrame")

    assert diag_frame.name == "CemToPdmBodyDiagReqFrame"
    assert diag_frame.length == 64
    assert diag_frame.startbit == 0
    teardown_scenario1()
  end

  test "Signal through fake CAN" do
    setup_scenario1()

    SignalBase.register_listeners(:sig0, ["WiperSpeedInfo"], :none, self())
    wiper = Payload.Descriptions.get_field_by_name(:desc, "WiperSpeedInfo")

    assert wiper.name == "WiperSpeedInfo"

    some_data = <<1,2,3,4,5,6,7,8>>

    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{wiper.id, some_data}])

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: signals, source: :test_source}}}
    assert List.keyfind(signals, "WiperSpeedInfo", 0) == {"WiperSpeedInfo", 1.0}

    assert_receive :cache_decoded
    assert_receive :cache_decoded
    teardown_scenario1()
  end

  test "Signal through fake CAN check that diag frame is untouched json" do
    setup_scenario1()

    SignalBase.register_listeners(:sig0, ["TesterPhysicalReqCEMHS"], :none, self())

    diagnostics = Payload.Descriptions.get_field_by_name(:desc, "TesterPhysicalReqCEMHS")
    assert diagnostics.name == "TesterPhysicalReqCEMHS"

    some_data = <<1,2,3,4,5,6,7,8>>

    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{diagnostics.id, some_data}])

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: signals, source: :test_source}}}

    <<some_data_received::size(64)>> = some_data
    assert List.keyfind(signals, "TesterPhysicalReqCEMHS", 0) ==
      {"TesterPhysicalReqCEMHS", some_data_received}

    assert_receive :cache_decoded
    assert_receive :cache_decoded
    teardown_scenario1()
  end

  test "Signal through fake CAN check that diag frame is untouched dbc" do
    setup_scenario1()

    SignalBase.register_listeners(:sig0, ["TesterPhysicalReqCEMHS"], :none, self())

    diagnostics = Payload.Descriptions.get_field_by_name(:desc, "TesterPhysicalReqCEMHS")
    assert diagnostics.name == "TesterPhysicalReqCEMHS"

    some_data = <<1,2,3,4,5,6,7,8>>

    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{diagnostics.id, some_data}])

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: signals, source: :test_source}}}
    assert_receive :cache_decoded # Wait for signals

    <<some_data_received::size(64)>> = some_data
    assert List.keyfind(signals, "TesterPhysicalReqCEMHS", 0) ==
      {"TesterPhysicalReqCEMHS", some_data_received}

    assert_receive :cache_decoded
    teardown_scenario1()
  end

  test "Signal through fake CAN check that diag frame is untouched dbc vcan1" do
    setup_scenario1()

    SignalBase.register_listeners(:sig1, ["CemToPdmBodyDiagReqFrame"], :none, self())

    diagnostics = Payload.Descriptions.get_field_by_name(:desc2, "CemToPdmBodyDiagReqFrame")
    assert diagnostics.name == "CemToPdmBodyDiagReqFrame"

    some_data = <<1,2,3,4,5,6,7,8>>

    Payload.Signal.handle_raw_can_frames(
      :can_vcan1_signal, :test_source,
      [{diagnostics.id, some_data}])

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: signals, source: :test_source}}}
    assert_receive :cache_decoded

    <<some_data_received::size(64)>> = some_data
    assert List.keyfind(signals, "CemToPdmBodyDiagReqFrame", 0) ==
      {"CemToPdmBodyDiagReqFrame", some_data_received}

    assert_receive :cache_decoded
    teardown_scenario1()
  end

  #test "Import canmatrix json" do
  #{:ok, _} = Payload.Descriptions.start_link({:desc, self(), canmatrix_file: "config/canmatrix.json"})
  #assert GenServer.stop(:desc) == :ok
  #end

  test "Regex DBC SG_ line #1" do
    line = ~s/ SG_ TestSignal : 55|16@0+ (0.01,0) [0|320] ""  BECM,CEM,CVM,ECM,FSM,PSCM,TCM\n/
    assert {:sg, data} = DBC.line(line)
    assert data.name == "TestSignal"
    assert data.startbit == 48
    assert data.length == 16
    assert data.factor == 0.01
    assert data.offset == 0
    assert data.margin_lo == 0
    assert data.margin_hi == 320
  end

  test "Regex DBC SG_ line #2" do
    line = ~s/ SG_ TestSignal : 54|15@0+ (0.04395,0) [0|1440.10965] ""  BCM,CEM,CVM,DEM,ECM,FSM,PSCM,SUM,TCM\n/
    assert {:sg, data} = DBC.line(line)
    assert data != :none
  end

  test "Import DBC file" do
    {:ok, _} = Payload.Descriptions.start_link({
      :cd, nil,
      [dbc_file: "../../configuration/can_files/EuCD/EuCD031_YD_HS_CAN_R00.dbc"],
      self()})
  end

  test "Regex DBC BA_ BO_ (CAN frame option)" do
    line = ~s/BA_ "TestSignal" BO_ 21 0;\n/
    assert {:babo, data} = DBC.line(line)
    assert data.can_id == 21
    assert data.option_name == "TestSignal"
    assert data.value == 0
  end

  test "Regex DBC BA_ SG_ (Signal option)" do
    line = ~s/BA_ "TestSignal" SG_ 298 TestSignal 1;\n/
    assert {:basg, data} = DBC.line(line)
    assert data.can_id == 298
    assert data.option_name == "TestSignal"
    assert data.signal_name == "TestSignal"
    assert data.value == 1
  end

  test "Regex DBC BA_ BO_ (CAN frame option, floating point values)" do
    line = ~s/BA_ "TestCycleTime" BO_ 1290 1000.000;\n/
    assert {:babo, data} = DBC.line(line)
    assert data.can_id == 1290
    assert data.option_name == "TestCycleTime"
    assert data.value == 1000.000
  end

  test "Send raw data via VCAN and read it back from cache" do
    setup_scenario1()

    assert Payload.Cache.read_channels(
      :cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    field = Payload.Descriptions.get_field_by_name(:desc, "TestSignalCntFrR")
    assert field.name == "TestSignalCntFrR"
    assert field.id == 0x2ef
    assert field.startbit == 48

    # Send raw data
    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{field.id, <<0, 0, 0, 0, 0, 0, 240, 0>>}])

    # Recieve value via signaling system
    assert_receive {:"$gen_cast", {:signal,
      %Message{name_values: [{"TestSignalCntFrR", value}], source: :test_source}}}
    assert value == 240
    assert_receive :cache_decoded

    # Receive value via cache system. Then assert the value from cache is the
    # same as the value received from the signaling system
    assert Payload.Cache.read_channels(
      :cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", value}]
    assert_receive :cache_decoded

    teardown_scenario1()
  end

  test "Update cache via signalbroker" do
    setup_scenario1()

    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]
    assert Payload.Cache.get_nbr_entries(:cache) == 0

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    SignalBase.publish(:sig0, [{"TestSignalCntFrR", 210}], :any)

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", 210}]}}}
    assert_receive :cache_decoded

    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 210}]
    assert Payload.Cache.get_nbr_entries(:cache) == 1

    # Write a signal that doesn't exist
    SignalBase.publish(:sig0, [{"Nothing", 230}], :any)

    :timer.sleep(2) # Sleep to make sure *nothing* happens :(
    assert Payload.Cache.get_nbr_entries(:cache) == 1 # Should still be 1

    # Update 2 values and assert the cache still only has 1 entry
    SignalBase.publish(:sig0, [
      {"TestSignalCntFrR", 140},
      {"TestSignalCntFrL", 150},
    ], :any)

    assert_receive :cache_decoded
    assert Payload.Cache.get_nbr_entries(:cache) == 1

    # Assert values
    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 140}]
    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrL"]) == [{"TestSignalCntFrL", 150}]

    # Update 3 values with 1 entry that will update a new frame in the cache
    SignalBase.publish(:sig0, [
      {"TestSignalCntFrR", 40},
      {"TestSignalCntFrL", 50},
      {"SteeringAngleCR", 60},
    ], :any)

    # Wait for 2 decodings, publish was on two different packets
    assert_receive :cache_decoded
    assert_receive :cache_decoded
    assert Payload.Cache.get_nbr_entries(:cache) == 2

    # Assert all published values
    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 40}]
    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrL"]) == [{"TestSignalCntFrL", 50}]
    assert Payload.Cache.read_channels(:cache, ["SteeringAngleCR"]) == [{"SteeringAngleCR", 60}]

    teardown_scenario1()
  end

  test "Update cache via signalbroker, make sure signals are decoded when needed" do
    setup_scenario1()

    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]
    assert Payload.Cache.get_nbr_entries(:cache) == 0
    assert Payload.Cache.get_nbr_entries_unpacked(:cache) == 0

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    SignalBase.publish(:sig0, [{"TestSignalCntFrR", 210}], :any)

    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", 210}]}}}
    assert_receive :cache_decoded

    # there is a listern so signal should exist unpacked
    assert Payload.Cache.get_nbr_entries_unpacked(:cache) == 1

    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", 210}]
    assert Payload.Cache.get_nbr_entries(:cache) == 1

    teardown_scenario1()
  end

  test "Send raw data via VCAN and read it back from cache, make sure its rendered invalid in cache" do
    setup_scenario1()

    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", :empty}]

    SignalBase.register_listeners(:sig0, ["TestSignalCntFrR"], :none, self())
    field = Payload.Descriptions.get_field_by_name(:desc, "TestSignalCntFrR")
    assert field.name == "TestSignalCntFrR"
    assert field.id == 0x2ef
    assert field.startbit == 48

    # Send raw data
    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{field.id, <<0, 0, 0, 0, 0, 0, 240, 0>>}])
    assert_receive :cache_decoded # Two, why?
    assert_receive :cache_decoded

    # Recieve value via signaling system
    assert_receive {:"$gen_cast", {:signal, %Message{name_values: [{"TestSignalCntFrR", value}], source: :test_source}}}
    assert value == 240

    # Receive value via cache system. Then assert the value from cache is the
    # same as the value received from the signaling system
    assert Payload.Cache.read_channels(:cache, ["TestSignalCntFrR"]) == [{"TestSignalCntFrR", value}]

    # both table in cache should be populated
    assert Payload.Cache.get_nbr_entries(:cache) == 1
    assert Payload.Cache.get_nbr_entries_unpacked(:cache) == 1

    # remove listener
    SignalBase.remove_listener(:sig0, "TestSignalCntFrR", self())

    # Send raw data, cache should be populated with id but not decoded.
    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{field.id, <<0, 0, 0, 0, 0, 0, 240, 0>>}])
    assert_receive :cache_update # Should result in a cache update

    # both id should be updated, this decoded should be purged (no listener)
    assert Payload.Cache.get_nbr_entries(:cache) == 1
    assert Payload.Cache.get_nbr_entries_unpacked(:cache) == 0

    teardown_scenario1()
  end

  defp setup_and_teardown() do
    setup_scenario1()
    teardown_scenario1()
  end

  test "Setup and teardown" do
    Enum.each(1..10, fn(_x) -> setup_and_teardown() end)
  end

  # INTERNAL

  defp setup do
    {:ok, _} = Util.Forwarder.start_link(self())

    {:ok, _} = SignalBase.start_link(:sig0, :any, nil)
    assert_receive :signal_base_ready, 500

    {:ok, _} = SignalBase.start_link(:sig1, :any, nil)
    assert_receive :signal_base_ready, 500
  end

  defp clean_up do
    :ok = GenServer.stop(:sig0)
    :ok = GenServer.stop(:sig1)
    assert Util.Forwarder.terminate() == :ok
  end

  @tag :run_now
  defp setup_scenario1 do
    setup()

    {:ok, _} = AppNgCan.start_link({{"vcan0",  :desc, :conn, :can_vcan0_signal, :writer, :cache, :sig0, String.to_atom("chassis"), "can"}, human_file: "../../configuration/human_files/cfile.json"})
    assert_receive {:ready_descriptors, :sig0}, 3_000

    {:ok, _} = AppNgCan.start_link({{"vcan1", :desc2, :conn2, :can_vcan1_signal, :writer2, :cache2, :sig1, String.to_atom("body"), "can"}, dbc_file: "../../configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc"})
    assert_receive {:ready_descriptors, :sig1}, 3_000
  end


  defp teardown_scenario1 do
    # do: assert GenServer.stop(:can_vcan0_app) == :ok
    assert GenServer.stop(Payload.Name.generate_name_from_namespace(String.to_atom("body"), :supervisor)) == :ok
    # assert GenServer.stop(:)
    assert GenServer.stop(Payload.Name.generate_name_from_namespace(String.to_atom("chassis"), :supervisor)) == :ok
    clean_up()
  end
end
