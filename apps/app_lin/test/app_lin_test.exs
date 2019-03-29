defmodule AppLinTest do
  use ExUnit.Case
  require Logger

  @file_single_signal "config/ldf_files/single_signal.ldf"

  @file_single_frame "config/ldf_files/single_frame.ldf"

  @file_single_schedule "config/ldf_files/single_schedule.ldf"

  @file_single_encoding "config/ldf_files/single_encoding.ldf"

  @file_single_representation "config/ldf_files/single_representation.ldf"

  @big_file "../../configuration/ldf_files/SPA1910_LIN18.ldf"
  # @big_file "config/ldf_files/SPA1910_LIN18.ldf"



  test "Read file with single signal" do
    l = Lin.Ldf.parse_file(@file_single_signal)

    assert l.frames == []
    assert l.scheduling == []
    assert l.signal_encoding_type == []
    assert l.signal_representation == []
    assert l.signals == [
      %Lin.Ldf.Signal{
        initial_value: -3,
        publisher: "AAC",
        size: 2,
        subscribers: ["CCM"],
        name: "AirClnrAdvErrNeg"},
      %Lin.Ldf.Signal{
        initial_value: 3,
        name: "AirClnrAdvErrSts",
        publisher: "AAC",
        size: 2,
        subscribers: ["CCM"]}
      ]

  end

  test "Read file with single frame" do
    l = Lin.Ldf.parse_file(@file_single_frame)

    assert l.frames == [%Lin.Ldf.Frame{
      frame_size: 1,
      id: 0x30,
      name: "AIULIN18Fr01",
      publisher: "AIU",
      signals: %Lin.Ldf.FrameSignals{
        signal_name: ["ErrRespAIU", "AirClngSts", "AirClngErrSts"],
        signal_offset: [7, 2, 0]}}
    ]
    assert l.scheduling == []
    assert l.signal_encoding_type == []
    assert l.signal_representation == []
    assert l.signals == []
  end

  test "Read file with single scheduling" do
    l = Lin.Ldf.parse_file(@file_single_schedule)

    assert l.scheduling == [%Lin.Ldf.SchedulingTable{
      frame_schedules: [
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "HVCHLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr05"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "15.000", frame_name: "HusLin18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "HVCHLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "SHMRLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "SHRRLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "5.000", frame_name: "AIULIN18Fr01"},
        %{frame_delay: "15.000", frame_name: "CPMLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr05"},
        %{frame_delay: "15.000", frame_name: "HusLin18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "SHMRLIN18Fr01"},
        %{frame_delay: "10.000", frame_name: "CCMLIN18Fr02"},
        %{frame_delay: "10.000", frame_name: "SHRRLIN18Fr01"},
        %{frame_delay: "15.000", frame_name: "CCMLIN18Fr03"}
      ],
      table_name: "CcmLin18ScheduleTable1"}
    ]
    assert l.signal_encoding_type == []
    assert l.signal_representation == []
    assert l.signals == []
    assert l.frames == []
  end

  test "Read file with single encoding" do
    l = Lin.Ldf.parse_file(@file_single_encoding)

    assert l.signal_encoding_type == [%Lin.Ldf.SignalEncodingType{
      encodings: %Lin.Ldf.SignalEncoding{
        logical: [
          %Lin.Ldf.Logical{name: "\"AirClngErrSts_OpenCircuit\"", value: 3},
          %Lin.Ldf.Logical{name: "\"AirClngErrSts_ShortCircuit\"", value: 2},
          %Lin.Ldf.Logical{name: "\"AirClngErrSts_Err\"", value: 1},
          %Lin.Ldf.Logical{name: "\"AirClngErrSts_NoErr\"", value: 0}
        ],
        physical: []},
      signal_name: "AirClngErrSts"}
    ]
    assert l.frames == []
    assert l.scheduling == []
    assert l.signal_representation == []
    assert l.signals == []
  end

  test "Read file with single representation" do
    l = Lin.Ldf.parse_file(@file_single_representation)

    assert l.signal_representation == [%Lin.Ldf.SignalRepresentation{
      encoding_type_name: "Boolean",
      signals: ["FanBoostVentnFlgRiAmprFanBoostVentnLimRe",
       "FanBoostVentnFlgRiFanBoostVentnFullDutyCycRe",
       "FanBoostVentnFlgRiFanBoostVentnSpRe",
       "FanBoostVentnFlgRiFanBoostVentnTLimRe",
       "FanBoostVentnFlgRiRpmFanBoostVentnMaxRe", "FanBoostVentnRstReRi",
       "HvCooltHeatrEnad", "HvCooltHeatrProtnOfSelfTmpHwProtn",
       "HvCooltHeatrProtnOfSelfTmpOvrheatg",
       "HvCooltHeatrProtnOfSelfTmpProtnOfSelfTmp",
       "HvCooltHeatrProtnOfSelfTmpProtnOfSelfTmpResd",
       "HvCooltHeatrSnsrFltCooltTInSnsrFlt", "HvCooltHeatrSnsrFltCooltTOutSnsrFlt",
       "HvCooltHeatrSnsrFltResdForSnsrFlt", "HvCooltHeatrSnsrFltTInMtrlSnsrFlt",
       "HvCooltHeatrSrvRqrdCircForDrvrShoOrOpen", "HvCooltHeatrSrvRqrdICnsOutOfRng",
       "HvCooltHeatrSrvRqrdMemErr", "HvCooltHeatrSrvRqrdSrvRqrd",
       "HvCooltHeatrSrvRqrdSrvRqrdResd", "HvCooltHeatrWarnCooltTOutOfRng",
       "HvCooltHeatrWarnFltInCom", "HvCooltHeatrWarnFltPrsnt",
       "HvCooltHeatrWarnFltPrsntResd", "HvCooltHeatrWarnHvOutOfRng",
       "HvCooltHeatrWarnULoOutOfRng", "SeatClimaReqForRowFirstRiSeatHeatErrRst",
       "SeatClimaReqForRowFirstRiSeatHeatFanErrRst",
       "SeatClimaReqForRowSecRiSeatHeatErrRst",
       "SeatClimaReqForRowSecRiSeatHeatFanErrRst", "VoltFanBoostVentnReLoAndOverRi"]}
    ]
    assert l.signal_encoding_type == []
    assert l.frames == []
    assert l.scheduling == []
    assert l.signals == []
  end

  test "Read big file" do
    Lin.Ldf.parse_file(@big_file)
  end

  @tag :lin_scheduler
  test "Test scheduling" do
    simple_initialize()

    l = Enum.at(Lin.Ldf.parse_file(@file_single_schedule).scheduling, 0).frame_schedules

    sleep_len = 2*Enum.reduce(l, 0, fn(x, acc) -> elem(Integer.parse(x.frame_delay), 0) + acc end)

    l2 = l ++ l

    start_time = System.monotonic_time(:millisecond)

    ldf_frames = Lin.Ldf.parse_file(@big_file).frames

    Enum.map(0..length(l2) - 1, fn(x) ->
      id = Enum.at(Enum.filter(ldf_frames, fn(y) -> Enum.at(l2, x).frame_name == y.name end), 0).id
      length = Enum.at(Enum.filter(ldf_frames, fn(y) -> Enum.at(l2, x).frame_name == y.name end), 0).frame_size
      assert_receive {:write_arbitration_frame, ^id, ^length}
    end)

    end_time = System.monotonic_time(:millisecond)

    # Allow some slack
    assert Lin.Scheduler.num_sent(:linudp_Lin_scheduler) >= 2*length(l)
    assert Lin.Scheduler.num_sent(:linudp_Lin_scheduler) < 4*length(l)

    assert end_time - start_time > sleep_len
    assert end_time - start_time < 2*sleep_len

    simple_terminate()
  end

  @tag :lin_scheduler
  test "Test scheduling - run once on the fly" do
    simple_initialize()

    ldf_frames = Lin.Ldf.parse_file(@big_file).frames

    :timer.sleep(500)

    :ok = Lin.Scheduler.run_pattern(:linudp_Lin_scheduler, "apps/app_lin/" <> @big_file, "CcmLin18ScheduleTable2", 1)
    :timer.sleep(500)

    id = Enum.at(Enum.filter(ldf_frames, fn(y) -> y.name == "BfrLin18Fr00" end), 0).id
    assert_receive({:write_arbitration_frame, ^id, _}, 1000)

    r = receive do
      {:write_arbitration_frame, ^id, _} -> false
    after
       1_000 -> true
    end

    assert r

    :ok = Lin.Scheduler.run_pattern(:linudp_Lin_scheduler, "apps/app_lin/" <> @big_file, "CcmLin18ScheduleTable2", 3)
    :timer.sleep(1500)

    assert_receive({:write_arbitration_frame, ^id, _}, 1000)
    assert_receive({:write_arbitration_frame, ^id, _}, 1000)
    assert_receive({:write_arbitration_frame, ^id, _}, 1000)

    r = receive do
      {:write_arbitration_frame, ^id, _} -> false
    after
      1_000 -> true
    end

    assert r

    assert Lin.Scheduler.num_sent(:linudp_Lin_scheduler) > 200

    simple_terminate()
  end

  defp fetch_lingering(t) do
    r = receive do
      _ -> true
    after
      1_000 -> false
    end

    case r do
      true -> assert (System.monotonic_time(:millisecond) - t) < 1000
        fetch_lingering(t)
        nil
      _ -> nil
    end
  end

  # @tag :lin_scheduler
  # test "Test scheduling - stop/start" do
  #   simple_initialize()
  #
  #   :ok = Lin.Scheduler.stop_pattern(:linudp_Lin_scheduler)
  #   assert_receive :lin_stop
  #
  #   r = receive do
  #     _ -> false
  #   after
  #     1_000 -> true
  #   end
  #
  #   IO.inspect(r, label: "R")
  #   assert r
  #
  #   :ok = Lin.Scheduler.start_pattern(:linudp_Lin_scheduler)
  #   assert_receive :lin_start
  #
  #   r = receive do
  #     _ -> true
  #   after
  #     1_000 -> false
  #   end
  #
  #   assert r
  #
  #   :ok = Lin.Scheduler.stop_pattern(:linudp_Lin_scheduler)
  #
  #   fetch_lingering(System.monotonic_time(:millisecond))
  #
  #   simple_terminate()
  # end

  @body "Lin"

  # @simple_lin_conf %{device_name: "lin", ldf_file: "apps/app_lin/config/ldf_files/SPA1910_LIN18.ldf", namespace: "Lin", schedule_autostart: true, schedule_file: "apps/app_lin/config/ldf_files/single_schedule.ldf", schedule_table_name: "CcmLin18ScheduleTable1", server_port: 2002, target_host: "127.0.0.1", target_port: 2003, type: "lin"}
  @simple_lin_conf %{device_name: "lin", ldf_file: "configuration/ldf_files/SPA1910_LIN18.ldf", namespace: "Lin", schedule_autostart: true, schedule_file: "apps/app_lin/config/ldf_files/single_schedule.ldf", schedule_table_name: "CcmLin18ScheduleTable1", server_port: 2002, target_host: "127.0.0.1", target_port: 2003, config_port: 4000, type: "lin", config: %{device_identifier: 8}}


  defp simple_initialize() do
    {:ok, _} = Util.Forwarder.start_link(self())
    {:ok, _} = SignalBase.start_link(:broker0_pid, String.to_atom(@body), nil)
    assert_receive :signal_base_ready, 500

    {:ok, _} = AppLin.start_link({String.to_atom(@body), :broker0_pid, @simple_lin_conf, 2010, '127.0.0.1', 2011, 4000, "master", "lin"})
    # {:ok, _} = AppLin.start_link({String.to_atom(@body), :broker0_pid, @simple_lin_conf, 2010, '127.0.0.1', 2011, "lin"})
    assert_receive {:ready_descriptors, :broker0_pid}, 3_000
  end

  defp simple_terminate() do
    assert GenServer.stop(Payload.Name.generate_name_from_namespace(String.to_atom(@body), :supervisor)) == :ok

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
