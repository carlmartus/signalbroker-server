defmodule GRPCClientTest do

  @body "BodyCANhs"

  require Logger

  def start() do
    subscribe_to_fan_speed("uninportant_message", setup_connection())
  end

  def start_custom_signal() do
    subscribe_to_signal("MirrCmdAtPassFold", @body, setup_connection())
  end

  def start_muliple_subscribers() do
    con = setup_connection()
    spawn(GRPCClientTest, :subscribe_to_signal, [["LoadAndStoreReqIdPen"], @body, con])
    spawn(GRPCClientTest, :subscribe_to_signal, [["TirePMonForDevDataByte3"], @body, con])
    spawn(GRPCClientTest, :subscribe_to_signal, [["MirrCmdAtPassFold"], @body, con])
    spawn(GRPCClientTest, :subscribe_to_signal, [["PassSeatActvSpplFct"], @body, con])
  end

  def start_hvac_hammer(value, freq) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    set_fan_speed(value, channel, freq)
  end

  def start_network_hammer(value, freq) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    set_network_value(value, channel, freq)
  end

  def test_send_receive() do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.SubscriberInfo.new(name: "grpc-elixir")
    # channel |> Base.SubscriberService.Stub.example_simple(request)
    channel |> Base.SubscriberService.Stub.example_simple(request)
  end

  def test_open_window() do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.ClientId.new(id: "grpc-elixir-source")
    # channel |> Base.SubscriberService.Stub.example_simple(request)
    channel |> Base.FunctionalService.Stub.open_pass_window(request)
  end

  def test_close_window() do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    request = Base.ClientId.new(id: "grpc-elixir-source")
    # channel |> Base.SubscriberService.Stub.example_simple(request)
    channel |> Base.FunctionalService.Stub.close_pass_window(request)
  end

  def setup_connection() do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    # Logger.info inspect {:ok, channel}
    channel
  end

  def send_stuff(message_string, channel) do
    request = Base.SubscriberInfo.new(name: message_string)
    channel |> Base.SubscriberService.Stub.example_simple(request)
  end

  def set_fan_speed(value, channel, freq) do
    # Logger.info "client start"
    source = Base.ClientId.new(id: "source_string")
    request = Base.SenderInfo.new(clientId: source, value: Base.Value.new(payload: value), frequency: freq)

    stream = channel |> Base.FunctionalService.Stub.set_fan_speed(request)
    # Logger.debug "received response #{inspect stream}"
    # Enum.each stream, fn (x) -> Logger.debug("client got response #{inspect x}") end
    # Logger.info "client stop"
  end

  def set_network_value(value, channel, freq) do
    # Logger.info "client start"
    source = Base.ClientId.new(id: "source_string")
    signal1 = Base.SignalId.new(name: "WinSwtReqToPass", namespace: Base.NameSpace.new(name: @body))
    signal2 = Base.SignalId.new(name: "WinSwtReqToPass1", namespace: Base.NameSpace.new(name: @body))
    signals_with_payload = [Base.Signal.new(id: signal1, payload: value), Base.Signal.new(id: signal2, payload: 3)]
    request = Base.PublisherConfig.new(clientId: source, frequency: freq, signals: signals_with_payload)

    stream = channel |> Base.NetworkService.Stub.publish_signals(request)
    # Logger.debug "received response #{inspect stream}"
    # Enum.each stream, fn (x) -> Logger.debug("client got response #{inspect x}") end
    # Logger.info "client stop"
  end

  def subscribe_to_fan_speed(message_string, channel) do
    # Logger.info "client start"
    source = Base.ClientId.new(id: message_string)
    request = Base.SubscriberRequest.new(clientId: source, onChange: false)
    {:ok, stream} = channel |> Base.FunctionalService.Stub.subscribe_to_fan_speed(request)

    # values = Enum.take(stream, 10)
    # Enum.each values, fn (x) ->
    #   Logger.debug("client got response #{inspect x}")
    # end

    Enum.each stream, fn (x) ->
      if(Mix.env == :test, do: Util.Forwarder.send({:subscription_received, x}))
      # Logger.debug("client got response #{inspect x}")
    end

    # Logger.info "client end"
  end

  def subscribe_to_signal(signals, namespace, channel) do
    subsignals = Enum.map(signals, fn(signal) ->
      Base.SignalId.new(name: signal, namespace: Base.NameSpace.new(name: namespace))
    end)
    # signal = [Base.SignalId.new(signal_name: signal, namespace: namespace)]
    request = Base.SubscriberConfig.new(clientId: Base.ClientId.new(id: "grpc-client"), signals: Base.SignalIds.new(signalId: subsignals), onChange: false)
    {:ok, stream} = channel |> Base.NetworkService.Stub.subscribe_to_signals(request)

    # values = Enum.take(stream, 10)
    # Enum.each values, fn (x) ->
    #   Logger.debug("client got response #{inspect x}")
    # end

    Enum.each stream, fn (x) ->
      if(Mix.env == :test, do: Util.Forwarder.send({:subscription_received, x}))
      # Logger.debug("client got response #{inspect x}")
    end

    # Logger.info "client end"
  end

  def send_example_simple_mulitple_times_helper do
    send_example_simple_mulitple_times("unimportant_message", setup_connection())
  end

  def send_example_simple_mulitple_times(message, channel) do
    spawn(GRPCClientTest, :subscribe_to_fan_speed, [message, channel])
    :timer.sleep(100)
    spawn(GRPCClientTest, :subscribe_to_fan_speed, [message <> message, channel])
    :timer.sleep(100)
    spawn(GRPCClientTest, :subscribe_to_fan_speed, [message <> message <> message, channel])
    :timer.sleep(100)
    spawn(GRPCClientTest, :subscribe_to_fan_speed, [message <> message <> message <> message, channel])
  end
end
