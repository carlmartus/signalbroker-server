
defmodule Base.FunctionalService.Server do
  use GRPC.Server, service: Base.FunctionalService.Service
  require Logger
  alias GRPC.Server
  alias Base.SignalId

  @gateway_pid GRPCService.Application.get_gateway_pid()

  @body :BodyCANhs

  @spec subscribe_to_fan_speed(Base.SubscriberRequest.t, GRPC.Server.Stream.t) :: any
  def subscribe_to_fan_speed(request, stream) do
    name = "grpc_handler" <> inspect self()

    pack_response = fn([signal], _timestamp, namespace) ->
      {channel, value} = signal
      Server.stream_send(stream, Base.Value.new(payload: value))
      value
    end

    GRPCSubscriber.start_link(String.to_atom(name), self(), [%SignalId{name: "HmiHvacFanLvlFrnt", namespace: %Base.NameSpace{name: Atom.to_string(@body)}}], String.to_atom(request.clientId.id), pack_response)
    lock_pid(stream)
  end

  defp lock_pid(_stream) do
    receive do
      :shutdown -> Logger.debug ("End of stream")
    end
  end


  @spec open_pass_window(Base.ClientId.t, GRPC.Server.Stream.t) :: Base.Empty.t
  def open_pass_window(request, _stream) do
    window_front_right(4)
    Base.Empty.new()
  end

  @spec close_pass_window(Base.ClientId.t, GRPC.Server.Stream.t) :: Base.Empty.t
  def close_pass_window(request, _stream) do
    window_front_right(2)
    Base.Empty.new()
  end

  @spec set_fan_speed(Base.SenderInfo.t, GRPC.Server.Stream.t) :: Base.Empty.t
  def set_fan_speed(request, _stream) do
    run = fn -> hvac_fan_speed(request.value.payload, request.clientId.id) end
    wrap_for_hammer("grpc_client_seed", run, request)
  end

  defp wrap_for_hammer(pid_unique_seed, run, request) do
    case PeriodicalHammer.start_link(pid_unique_seed, run, request.frequency) do
      :one_shot ->
        run.()
        _ -> :ok
    end
    Base.Empty.new()
  end


  # @spec example_simple(Base.SubscriberInfo.t, GRPC.Server.Stream.t) :: Base.SignalResponse.t
  # def example_simple(request, _stream) do
  #   Base.SignalResponse.new(message: "Hello from aleks #{request.name}")
  # end


  # @spec example_simple_input_stream(Helloworld.Hell../service_client/priv/static_files/js/web_car_chassis.jsoRequest.t, GRPC.Server.Stream.t) :: any
  # def example_simple_input_stream(request, _stream) do
  #   Logger.debug("received message request: #{request.name}")
  #   Base.SignalResponse.close pass window callednew(message: "Hello compined with request #{request.name}")
  # end


  #
  # def test_run() do
  #   repeat_n(1000, &open_window_front_right/0, 10)
  # end

  def repeat_n(times, fun, delay \\ 0) do
    Enum.map(1..times, fn(_x) ->
       fun.()
       :timer.sleep(delay)
     end)
  end



  def window_front_right(data) do
    # funkar
    target_frame = "DDMBodyFr01"

    #VAL_ 48 WinSwtReqToPass 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";
    #VAL_ 48 WinSwtReqToPassRe 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"WinSwtReqToPass", data},
      {"WinSwtReqToPass_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end

  def window_rear_right(data) do
    target_frame = "DDMBodyFr01"

    # funkar
    #VAL_ 48 WinSwtReqToPass 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";
    #VAL_ 48 WinSwtReqToPassRe 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"WinSwtReqToPassRe", data},
      {"WinSwtReqToPassRe_UB", 1},
      # {"WinPosnStsAtDrvrRe", 2},
      # {"WinPosnStsAtDrvrRe_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end

  def mirror() do
    target_frame = "DDMBodyFr01"

    #VAL_ 48 WinSwtReqToPass 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";
    #VAL_ 48 WinSwtReqToPassRe 0 "WinPosnReq_Idle" 1 "WinPosnReq_UpMan" 2 "WinPosnReq_UpAut" 3 "WinPosnReq_DwnMan" 4 "WinPosnReq_DwnAut" 5 "WinPosnReq_NotDefd";
    #VAL_ 48 MirrCmdAtPassFold 0 "MirrFoldCmdTyp_Idle" 1 "MirrFoldCmdTyp_FoldIn" 2 "MirrFoldCmdTyp_FoldOut";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"MirrCmdAtPassFold", 2},
      {"MirrCmdAtPassGroup_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end

  def close_window_global() do
    # funkar
    target_frame = "CEMBodyFr02"

    # VAL_ 64 GlbWinCmd 0 "OpenClsGlbCmd_Idle" 1 "OpenClsGlbCmd_GlobalOpenWindow" 2 "OpenClsGlbCmd_GlobalCloseWindowAndSunroof" 3 "OpenClsGlbCmd_GlobalCloseWindow" 4 "OpenClsGlbCmd_GlobalStop" 5 "OpenClsGlbCmd_Resd1" 6 "OpenClsGlbCmd_Resd2" 7 "OpenClsGlbCmd_Resd3";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"GlbWinCmd", 2},
      {"GlbWinCmd_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end


  def passenger_seat_massage() do
    # funkar ej
    target_frame = "PsmpBodyFr01"

    #VAL_ 160 PassSeatMassgFctOnOff 0 "OnOff1_Off" 1 "OnOff1_On";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"PassSeatMassgFctOnOff", 0},
      {"PassMassgRunng", 0},
      {"PassMassgRunng_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end

  def driver_seat_massage() do
    # funkar er
    target_frame = "PSMDBodyFr01"

    #VAL_ 160 PassMassgRunng 0 "OnOff1_Off" 1 "OnOff1_On";
    #VAL_ 144 DrvrSeatMassgFctMassgInten 0 "MassgIntenLvl_IntenLo" 1 "MassgIntenLvl_IntenNorm" 2 "MassgIntenLvl_IntenHi";
    #VAL_ 144 DrvrSeatMassgFctMassgProg 0 "MassgProgTyp_Prog1" 1 "MassgProgTyp_Prog2" 2 "MassgProgTyp_Prog3" 3 "MassgProgTyp_Prog4" 4 "MassgProgTyp_Prog5";
    #VAL_ 144 DrvrSeatMassgFctMassgSpdLvl 0 "MassgIntenLvl_IntenLo" 1 "MassgIntenLvl_IntenNorm" 2 "MassgIntenLvl_IntenHi";
    #VAL_ 144 DrvrMassgRunng 0 "OnOff1_Off" 1 "OnOff1_On";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"DrvrSeatMassgFctOnOff", 1},
      {"DrvrSeatMassgFctMassgInten", 2},
      {"DrvrSeatMassgFctMassgProg", 3},
      {"DrvrSeatMassgFctMassgSpdLvl", 2},
      {"DrvrMassgRunng", 1},
      {"DrvrMassgRunng_UB", 1},
      # {"DrvrSeatSwtAdjmtOfSpplFctHozlSts", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end

  # interval 0..7
  def hvac_fan_speed(data, source) do
    target_frame = "CEMBodyFr14"

    # funkar
    # CM_ SG_ 320 HmiHvacFanLvlFrnt "User requested fan level for first row.";
    # CM_ SG_ 320 HmiHvacFanLvlRe "User requested fan level for second row";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"HmiHvacFanLvlFrnt", data},
      {"HmiHvacFanLvlFrnt_UB", 1},
      # {"HmiHvacFanLvlRe", 0},
      # {"HmiHvacFanLvlRe_IB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, String.to_atom(source), @body)
  end

  def hvac_ac_on() do
    # funkar ej
    target_frame = "CEMBodyFr15"

    # CM_ SG_ 320 HmiHvacFanLvlFrnt "User requested fan level for first row.";
    # CM_ SG_ 320 HmiHvacFanLvlRe "User requested fan level for second row";

    inital_value =
      case SignalServerProxy.read_values(@gateway_pid, [target_frame], @body) do
        [{_, :empty}] -> 0
        [{_, value}] -> value
      end

    channels_with_values =
    [
      {target_frame, inital_value},
      {"HmiCmptmtCoolgReq", 1},
      {"HmiCmptmtCoolgReq_UB", 1},
    ]
    SignalServerProxy.publish(@gateway_pid, channels_with_values, :source, @body)
  end
end
