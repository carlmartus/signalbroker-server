defmodule GRPCServiceTest do
  use ExUnit.Case, async: false

  @gateway_pid GRPCService.Application.get_gateway_pid()

  @body "BodyCANhs"
  @lin "Lin"

  test "setup connection" do
    channel = GRPCClientTest.setup_connection()
    assert channel.host == "localhost"
    assert channel.port == 50051
  end

  test "make grpc call, (OpenPassWindow) make sure it reaches cache, grpc -> cache" do
    simple_initialize()

    assert Payload.Cache.read_channels(:cache0, ["DDMBodyFr01"]) == [{"DDMBodyFr01", :empty}]
    GRPCClientTest.test_open_window()
    assert_receive :cache_decoded
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass_UB"]) == [{"WinSwtReqToPass_UB", 1}]
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass"]) == [{"WinSwtReqToPass", 4}]
    # TODO aren't we expecting the raw frame here?
    assert Payload.Cache.read_channels(:cache0, ["DDMBodyFr01"]) == [{"DDMBodyFr01", 0}]
    simple_terminate()
  end

  test "make grpc call, (ClosePassWindow) make sure it reaches cache, grpc -> cache" do
    simple_initialize()

    assert Payload.Cache.read_channels(:cache0, ["DDMBodyFr01"]) == [{"DDMBodyFr01", :empty}]
    GRPCClientTest.test_close_window()
    assert_receive :cache_decoded
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass_UB"]) == [{"WinSwtReqToPass_UB", 1}]
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass"]) == [{"WinSwtReqToPass", 2}]
    # TODO aren't we expecting the raw frame here?
    assert Payload.Cache.read_channels(:cache0, ["DDMBodyFr01"]) == [{"DDMBodyFr01", 0}]
    simple_terminate()
  end

  @tag :this3
  test "make functional (set_fan_speed) hammer call with one shot, make sure it reaches cache, grpc -> cache" do
    simple_initialize()

    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", :empty}]
    GRPCClientTest.start_hvac_hammer(12, 0)
    assert_receive :cache_decoded
    # TODO aren't we expecting the raw frame here?
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", 12}]
    simple_terminate()
  end

  test "make network hammer call with one shot, make sure it reaches cache, grpc -> cache" do
    simple_initialize()

    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", :empty}]
    GRPCClientTest.start_hvac_hammer(12, 0)
    assert_receive :cache_decoded
    # TODO aren't we expecting the raw frame here?
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", 12}]
    simple_terminate()
  end

  @tag :this14
  test "make hammer call with 10 hz, make sure it reaches cache and make sure it's stoppable, grpc -> cache" do
    simple_initialize()

    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", :empty}]
    GRPCClientTest.start_hvac_hammer(12, 100)
    assert_receive :cache_decoded

    # TODO aren't we expecting the raw frame here?
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", 12}]


    GRPCClientTest.start_hvac_hammer(12, 0)
    # stop it again
    # once it's stopped write to cache and chech that it's not updated again
    SignalServerProxy.publish(@gateway_pid, [{"HmiHvacFanLvlFrnt", 5}], :none, String.to_atom(@body))
    assert_receive :cache_decoded
    :timer.sleep(100)
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", 5}]

    simple_terminate()
  end

  @tag :this2
  test "publish raw bytes make sure they arrive as published" do
    simple_initialize
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")

    <<expected::size(16)>> = <<256::size(16)>>

    spawn(GRPCClientTest, :subscribe_to_signal, [["CCMVFCVectorFrame"], @body, GRPCClientTest.setup_connection()])

    :timer.sleep(500)

    assert Payload.Cache.read_channels(:cache0, ["CCMVFCVectorFrame"]) == [{"CCMVFCVectorFrame", :empty}]
    source = Base.ClientId.new(id: "publisher_string")
    signal1 = Base.SignalId.new(name: "CCMVFCVectorFrame", namespace: Base.NameSpace.new(name: @body))
    signals_with_payload = [
      Base.Signal.new(id: signal1, raw: <<expected::size(16)>>)
    ]
    request = Base.PublisherConfig.new(clientId: source, frequency: 0, signals: Base.Signals.new(signal: signals_with_payload))
    stream = channel |> Base.NetworkService.Stub.publish_signals(request)
    assert_receive :cache_decoded

    assert Payload.Cache.read_channels(:cache0, ["CCMVFCVectorFrame"]) == [{"CCMVFCVectorFrame", expected}]

    :timer.sleep(500)

    assert_receive {:subscription_received, {:ok, %Base.Signals{signal: [response | t]}}}
    assert response.payload == {:integer, expected}
    assert response.raw == <<expected::size(16)>>
    assert response.id.name == "CCMVFCVectorFrame"
    assert response.id.namespace.name == @body



    simple_terminate
  end

  @tag :this4
  test "publish signal and read it using readfunction" do
    simple_initialize
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    # check empty...
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", :empty}]
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass"]) == [{"WinSwtReqToPass", :empty}]

    source = Base.ClientId.new(id: "source_string")
    signal1 = Base.SignalId.new(name: "HmiHvacFanLvlFrnt", namespace: Base.NameSpace.new(name: @body))
    signal2 = Base.SignalId.new(name: "WinSwtReqToPass", namespace: Base.NameSpace.new(name: @body))
    signal3 = Base.SignalId.new(name: "CEMBodyDevFr15", namespace: Base.NameSpace.new(name: @body))
    signal4 = Base.SignalId.new(name: "BfrLin18Fr00", namespace: Base.NameSpace.new(name: @lin))
    signal5 = Base.SignalId.new(name: "WinPosnStsDrv", namespace: Base.NameSpace.new(name: @body))

    signals_with_payload = [
      Base.Signal.new(id: signal1, payload: {:integer, 3}),
      Base.Signal.new(id: signal2, payload: {:double, 0.5}),
      Base.Signal.new(id: signal3, payload: {:double, 7.5}),
      Base.Signal.new(id: signal4, payload: {:arbitration, true}),
      Base.Signal.new(id: signal5, payload: {:integer, 23}, raw: <<01,02>>)
    ] |> Enum.sort

    request = Base.PublisherConfig.new(clientId: source, frequency: 0, signals: Base.Signals.new(signal: signals_with_payload))

    # now publish
    stream = channel |> Base.NetworkService.Stub.publish_signals(request)

    assert_receive :cache_decoded

    # let read

    signals = [
      signal1, signal2, signal3, signal4, signal5
    ]

    request = Base.SignalIds.new(signalId: signals)
    response = Base.NetworkService.Stub.read_signals(channel, request)

    {:ok, %Base.Signals{signal: signals}} = response
    [returned_signal | t] = signals |> Enum.sort
    assert returned_signal.payload == {:empty, true}
    assert returned_signal.id.name == "BfrLin18Fr00"
    assert returned_signal.id.namespace.name == @lin
    assert returned_signal.raw == <<>>

    [returned_signal | t] = t
    assert returned_signal.payload == {:double, 7.5}
    assert returned_signal.id.name == "CEMBodyDevFr15"
    assert returned_signal.id.namespace.name == @body
    assert returned_signal.raw == <<>>

    [returned_signal | t] = t
    assert returned_signal.payload == {:integer, 3}
    assert returned_signal.id.name == "HmiHvacFanLvlFrnt"
    assert returned_signal.id.namespace.name == @body
    assert returned_signal.raw == <<3>>

    [returned_signal | t] = t
    assert returned_signal.id.name == "WinPosnStsDrv"
    assert returned_signal.id.namespace.name == @body
    assert returned_signal.raw == <<01,02>>

    [returned_signal | t] = t
    assert returned_signal.payload == {:double, 0.5}
    assert returned_signal.id.name == "WinSwtReqToPass"
    assert returned_signal.id.namespace.name == @body
    assert returned_signal.raw == <<>>

    simple_terminate()
  end

  @tag :this10
  test "fetch signals from server" do
    simple_initialize()

    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.NameSpace.new(name: @body)
    {:ok, response} = Base.SystemService.Stub.list_signals(channel, request)
    assert (Enum.count(response.frame) > 0)
    [first | rem] = response.frame

    assert ((%Base.SignalInfo{id: %Base.SignalId{name: "DDMBodyFr01", namespace: %Base.NameSpace{name: "BodyCANhs"}}, metaData: %Base.MetaData{description: "", isRaw: false, max: 0, min: 0, size: 64, unit: ""}}) == first.signalInfo)

    [firstkid | rem] = first.childInfo
    assert ((%Base.SignalInfo{id: %Base.SignalId{name: "ChdLockgProtnFailrStsToHmi_UB", namespace: %Base.NameSpace{name: "BodyCANhs"}}, metaData: %Base.MetaData{description: "", isRaw: false, max: 0, min: 0, size: 1, unit: ""}} == firstkid))

    simple_terminate()
  end


  @tag :this10
  test "fetch signals from server - return empty list" do
    simple_initialize()

    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.NameSpace.new(name: "made_up_namespace")
    {:ok, response} = Base.SystemService.Stub.list_signals(channel, request)
    assert (Enum.count(response.frame) == 0)

    simple_terminate()
  end

  @tag :this11
  test "fetch signals from server - use virtual network" do
    simple_initialize()

    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.NameSpace.new(name: "Virtual")
    {:ok, response} = Base.SystemService.Stub.list_signals(channel, request)
    assert (Enum.count(response.frame) == 0)

    simple_terminate()
  end


  @tag :this12
  test "get configuration" do
    simple_initialize()

    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.Empty.new()
    {:ok, response} = Base.SystemService.Stub.get_configuration(channel, request)
    assert (Enum.count(response.networkInfo) == 2)

    simple_terminate()
  end


  test "write signal and make sure it reaches cache" do
    simple_initialize()
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", :empty}]
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass"]) == [{"WinSwtReqToPass", :empty}]

    source = Base.ClientId.new(id: "source_string")
    namespace = Base.NameSpace.new(name: @body)
    signal1 = Base.SignalId.new(name: "HmiHvacFanLvlFrnt", namespace: namespace)
    signal2 = Base.SignalId.new(name: "WinSwtReqToPass", namespace: namespace)
    signal3 = Base.SignalId.new(name: "CEMBodyDevFr15", namespace: namespace)
    signal4 = Base.SignalId.new(name: "BfrLin18Fr00", namespace: Base.NameSpace.new(name: @lin))

    signals_with_payload = [
      Base.Signal.new(id: signal1, payload: {:integer, 3}),
      Base.Signal.new(id: signal2, payload: {:double, 0.5}),
      Base.Signal.new(id: signal3, payload: {:double, 7.5}),
      Base.Signal.new(id: signal4, payload: {:arbitration, true})
    ]
    request = Base.PublisherConfig.new(clientId: source, frequency: 0, signals: Base.Signals.new(signal: signals_with_payload))

    stream = channel |> Base.NetworkService.Stub.publish_signals(request)

    assert_receive :cache_decoded

    :timer.sleep(500)

    assert Payload.Cache.read_channels(:cache0, ["HmiHvacFanLvlFrnt"]) == [{"HmiHvacFanLvlFrnt", 3}]
    assert Payload.Cache.read_channels(:cache0, ["WinSwtReqToPass"]) == [{"WinSwtReqToPass", 0.5}]
    assert Payload.Cache.read_channels(:cache0, ["CEMBodyDevFr15"]) == [{"CEMBodyDevFr15", 7.5}]
    # arbitration doesn't reach cache....
    assert Payload.Cache.read_channels(:cache0, ["BfrLin18Fr00"]) == [{"BfrLin18Fr00", :empty}]

    simple_terminate()
  end

  require Logger

  @tag :this5
  test "subscribe to signal and make sure it arrives from can, cache -> grpc" do
    simple_initialize()

    field = Payload.Descriptions.get_field_by_name(Payload.Name.generate_name_from_namespace(String.to_atom(@body), :desc), "WinSwtReqToPass")
    spawn(GRPCClientTest, :subscribe_to_signal, [["WinSwtReqToPass", "MirrFoldStsAtDrvr"], @body, GRPCClientTest.setup_connection()])

    :timer.sleep(500)
    Payload.Signal.handle_raw_can_frames(
      :can_vcan0_signal, :test_source,
      [{field.id, <<0x12, 0x34,0x56,0x78,0xab,0xcd,0xef,0x01>>}])


    assert_receive {:subscription_received, {:ok, %Base.Signals{signal: signals}}}

    [response | t] = signals |> Enum.sort()
    assert response.payload == {:integer, 7}
    assert response.id.name == "MirrFoldStsAtDrvr"
    assert response.id.namespace.name == @body

    [response | t] = t
    assert response.payload == {:integer, 1}
    assert response.id.name == "WinSwtReqToPass"
    assert response.id.namespace.name == @body

    simple_terminate()
  end

  @tag :this1
  test "subscribe to signal and make sure it arrives from signal broker" do
    simple_initialize()

    # field = Payload.Descriptions.get_field_by_name(Payload.Name.generate_name_from_namespace(String.to_atom(@body), :desc), "WinSwtReqToPass")
    spawn(GRPCClientTest, :subscribe_to_signal, [["WinSwtReqToPass"], @body, GRPCClientTest.setup_connection()])

    :timer.sleep(500)
    SignalServerProxy.publish(@gateway_pid, [{"WinSwtReqToPass", 5}], :none, String.to_atom(@body))

    assert_receive {:subscription_received, {:ok, %Base.Signals{signal: [response | t]}}}
    assert response.payload == {:integer, 5}
    assert response.id.name == "WinSwtReqToPass"
    assert response.id.namespace.name == @body

    simple_terminate()
  end

  @tag :that2
  test "subscribe to fan speed" do
    simple_initialize()
    spawn(GRPCClientTest, :subscribe_to_fan_speed, ["source_string", GRPCClientTest.setup_connection()])
    :timer.sleep(500)
    SignalServerProxy.publish(@gateway_pid, [{"HmiHvacFanLvlFrnt", 3}], :none, String.to_atom(@body))

    assert_receive {:subscription_received, {:ok, response}}
    assert response.payload == 3

    simple_terminate()
  end


  @simple_conf %{
    BodyCANhs: %{signal_base_pid: :broker0_pid, signal_cache_pid: :cache0, type: "can"},
    Virtual: %{signal_base_pid: :broker1_pid, signal_cache_pid: :cache1, type: "virtual"},
  }

  # defp simple_initialize() do
  #   # Application.ensure_all_started(:grpc_service,  :permanent)
  #   {:ok, _} = Util.Forwarder.start_link(self())

  require Logger

  defp simple_initialize() do
    # Application.ensure_all_started(:grpc_service,  :permanent)
    {:ok, pid} = Util.Forwarder.start_link(self())

    {:ok, pid} = SignalServerProxy.start_link({@gateway_pid, @simple_conf, String.to_atom(@body)})
    assert_receive :signal_proxy_ready, 500
    {:ok, pid} = SignalBase.start_link(:broker0_pid, String.to_atom(@body), nil)
    assert_receive :signal_base_ready, 500
    # {:ok, _} = SignalBase.start_link(:broker1_pid, :any, nil)
    # {:ok, _} = SignalBase.start_link(:broker2_pid, :any, nil)

    {:ok, pid} = AppNgCan.start_link({{"vcan0", Payload.Name.generate_name_from_namespace(String.to_atom(@body), :desc), :conn, :can_vcan0_signal, :writer, :cache0, :broker0_pid, String.to_atom(@body), "can"}, dbc_file: "../../configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc"})
    assert_receive {:ready_descriptors, :broker0_pid}, 3_000
  end

  defp simple_terminate() do
    # Application.stop(:grpc_service)
    close_processes([@gateway_pid, :broker0_pid])
    close_processes([(Payload.Name.generate_name_from_namespace(String.to_atom(@body), :supervisor))])

    # assert GenServer.stop(Payload.Name.generate_name_from_namespace(String.to_atom(@body), :supervisor)) == :ok

    assert Util.Forwarder.terminate() == :ok
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end

  defp close_process(p) do
    :ok = GenServer.stop(p, :normal)
    assert_down(p)
  end

  defp close_processes(pids), do: pids |> Enum.map(&close_process/1)

end
