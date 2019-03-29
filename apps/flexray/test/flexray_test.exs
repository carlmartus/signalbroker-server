defmodule FlexRayTest do
  use ExUnit.Case


  @fibex_file "../../configuration/fibex_files/SPA0911_160121_BackBone_VCC.xml"
  @flexray_dump "../../test_data/flexray.dump"

  defmodule Config, do: defstruct [
        :type, :fibex_file
      ]

  require Logger
  @tag :flexray2
  test "Receiving FlexRay frames" do
    setup()

    conf = %Config{type: "flexray", fibex_file: @fibex_file}

    FlexRay.start_link({:FlexrayBackbone,
      {:server, :desc, :writer, :signal, :cache, :sig0, conf, '127.0.0.1', 54774}})

    # frames = SignalBase.get_channels_by_tag(:sig0, :raw, self())
    frames = SignalBase.get_channels(:sig0, self())
    assert (Enum.count frames) == 0

    # on raspberry pi this is slow...
    assert_receive {:ready_descriptors, :sig0}, 100_000

    # frames = SignalBase.get_channels_by_tag(:sig0, :raw, self())
    frames = SignalBase.get_channels(:sig0, self())
    assert (Enum.count frames) != 0

    {:ok, dump} = File.read(@flexray_dump)

    Kernel.send(:server, {:tcp, 0, dump})

    for _i <- 1..1279 do
      assert_receive :cache_update, 1_000
    end

    assert [{"HmiHvacFanLvlFrnt", 10}] == Payload.Cache.read_channels(:cache, ["HmiHvacFanLvlFrnt"])
    assert [{"SpdInHznPosn", -12.8}] == Payload.Cache.read_channels(:cache, ["SpdInHznPosn"])

    #assert GenServer.stop(p) == :ok
    clean_up()

  end


  @tag :flexray
  test "Fibex parsing" do

    fibex = Fibex_Parser.load(@fibex_file)

    frame2 = fibex.frames[{26,13}]

    assert frame2 == %{byte_length: '32',
                       id: 'ID_cfe1eeaf-41a6-41fc-9439-5ec6a6ebf698',
                       name: 'IhuBackBoneFr03',
                       pdu_instances: [
                         %{
                           bit_position: '0',
                           id: 'ID_35b0d779-a405-4470-8a2f-61962e4175c1',
                           is_high_low_byte_order: 'false',
                           pdu_ref: 'ID_39cb4a83-b911-46d6-a7d7-a6efcec5624a'
                         }
                       ]
                      }

    assert 1 == Enum.reduce(fibex.pdus['ID_39cb4a83-b911-46d6-a7d7-a6efcec5624a'][:signal_instances], 0, fn signal, acc ->
      case signal[:signal_ref] do
        'ID_6ad5fe7a-a928-4c7a-a5b5-1c5961cb78f1' ->
          assert signal == %{bit_position: '86',
                             id: 'ID_04e385f1-6768-4e4e-bb0a-085d0ae15815',
                             is_high_low_byte_order: 'true',
                             signal_ref: 'ID_6ad5fe7a-a928-4c7a-a5b5-1c5961cb78f1',
                             signal_update_bit_position: nil
                            }
          assert fibex.signals['ID_6ad5fe7a-a928-4c7a-a5b5-1c5961cb78f1'] == %{default_value: 64.0,
                                                                               factor: 0.2,
                                                                               is_signed: false,
                                                                               length: 9,
                                                                               max: 89.4,
                                                                               min: -12.8,
                                                                               name: "SpdInHznPosn",
                                                                               offset: -12.8,
                                                                               is_pdu: false
                                                                              }
          acc + 1
        _ -> acc
      end
    end)

    fs = Fibex_Parser.frameid2signals(fibex)

    assert "SpdInHznPosn" in Enum.reduce(fs[{26,13}], [], fn signal, acc -> acc ++ [signal[:name]] end)
    assert "VcmBackBoneDiagReqNpdu8" in Enum.reduce(fs[{94,26}], [], fn signal, acc -> acc ++ [signal[:name]] end)

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

end
