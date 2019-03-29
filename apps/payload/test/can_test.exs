defmodule CanTest do
  use ExUnit.Case
  alias SignalBase.Message

  # Create a suporvised instance.
  # See code for `AppNgCan.start_link` for clarification.
  test "test create message" do
    supervised_start()
    GenServer.cast(:canWriter, {:signal, %Message{name_values: [{WheelSpeedReR, 10}, {FuelLevelIndicated, 4}]}})
    #read out the code generated from canwriter and then canconnector...

    supervised_stop()
  end

  def supervised_start() do
    Process.register(self(), :test)
    Util.Forwarder.start_link(self())

    assert {:ok, _} = SignalBase.start_link(:sig0, :any, nil)

    conf_line = %{
      type: "can",
      human_file: "../../configuration/human_files/cfile.json",
      device_name: "vcan0",
      namespace: "chassis",
    }

    assert {:ok, _} = AppNgCan.start_link({{
      "vcan0",
      :desc,
      :canConnector,
      :canSignal,
      :canWriter,
      :canCache,
      :sig0, :chassis, "can"}, conf_line})

      # Wait for DBC files to be parsed
    assert_receive {:ready_descriptors, :sig0}
  end

  def supervised_stop() do
    assert GenServer.stop(:sig0) == :ok
    assert Util.Forwarder.terminate() == :ok
  end

  describe "Varying payload size" do
    @composed <<48, 57, 192, 100>>

    test ".dbc frame line" do
      # Taken from:
      # configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc

      {:bo, info} = DBC.line("BO_ 1407 CEMBodyMstCfg: 4 CEM\n")
      assert info.can_id == 1407
      assert info.name == "CEMBodyMstCfg"
      assert info.size_bytes == 4
      assert info.tag == "CEM"
    end

    test "compose" do
      {:ok, dbc} = Payload.Descriptions.start_link({:dbc_pid, nil, [
        dbc_file: "../../configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc"
      ], nil})

      # SG_ BodyCntrForMissCom : 31|8@0+ (1.0, 0.0) [0.0|255.0] "NoUnit" CCM, DDM, PDM, POT, PSMD, PSMP, TEM0, TRM
      # SG_ BodyCntrForMissCom_UB : 22|1@0+ (1,0) [0|1] "" CCM, DDM, PDM, POT, PSMD, PSMP, TEM0, TRM
      # SG_ MstCfgIDBodyCAN : 7|16@0+ (1.0, 0.0) [0.0|65535.0] "NoUnit" CCM, DDM, PDM, POT, PSMD, PSMP, TEM0, TRM
      # SG_ MstCfgIDBodyCAN_UB : 23|1@0+ (1,0) [0|1] "" CCM, DDM, PDM, POT, PSMD, PSMP, TEM0, TRM

      fields_with_values = [
        {"BodyCntrForMissCom", 100},
        {"BodyCntrForMissCom_UB", 1},
        {"MstCfgIDBodyCAN", 12345},
        {"MstCfgIDBodyCAN_UB", 1},
      ]
      |> Enum.map(fn({name, value}) ->
        {Payload.Descriptions.get_field_by_name(dbc, name), value}
      end)

      assert Payload.Descriptions.build_payload(dbc, fields_with_values) ==
        @composed

      assert GenServer.stop(dbc) == :ok
    end

    test "decompose" do
      {:ok, dbc} = Payload.Descriptions.start_link({:dbc_pid, nil, [
        dbc_file: "../../configuration/can_files/SPA0610/SPA0610_140404_BodyCANhs.dbc"
      ], nil})

      parsed = Payload.Descriptions.get_info_map(dbc, 1407, @composed)
               |> Enum.sort()

      parsed_value = fn(key) ->
        parsed
        |> List.keyfind(key, 0)
        |> elem(1)
      end

      # Check that it's the same as in test case "compose"
      assert parsed_value.("BodyCntrForMissCom") == 100
      assert parsed_value.("BodyCntrForMissCom_UB") == 1
      assert parsed_value.("MstCfgIDBodyCAN") == 12345
      assert parsed_value.("MstCfgIDBodyCAN_UB") == 1

      assert GenServer.stop(dbc) == :ok
    end
  end
end
