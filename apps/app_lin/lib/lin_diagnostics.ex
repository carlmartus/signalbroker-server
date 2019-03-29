defmodule Lin.Diagnostics do

  use GenServer
  require Logger

  defstruct [
    :signal_server_proxy,
    req: "",
    resp: "",
    flow_mode: "",
    namespace: nil
  ]

  # CLIENT

   
 def starthelper do
   start_link(:gateway_pid)
   setup_diagnostics("MasterReq", "SlaveResp", [flow_mode: :auto], :Lin)
   sendraw(<<0x72, 0x22, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x00>>)
 end


  def start_link(signal_server_proxy) do
    state = %__MODULE__{signal_server_proxy: signal_server_proxy}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def sendraw(payload) when is_binary(payload) do
    GenServer.call(__MODULE__, {:send_raw, payload})
  end

  @doc """
    if you dont provide namespace you will end up using the default namespace which is specified in the config.ex file.
  """
  def setup_diagnostics(req_name, resp_name, flow_mode, namespace \\ nil) do
    GenServer.call(__MODULE__, {:populate_state, resp_name, req_name, flow_mode, namespace})
    GenServer.call(__MODULE__, {:start_subscribe})
  end

  # SERVER

  def init(state) do
    {:ok, state}
  end

  def handle_call({:populate_state, resp_signal, req_signal, flow_mode, namespace}, _from, state) do
    state = %__MODULE__{state | resp: resp_signal, req: req_signal, flow_mode: flow_mode, namespace: namespace}
    {:reply, :ok, state}
  end

  def handle_call({:start_subscribe}, _from, state) do
    SignalServerProxy.register_listeners(state.signal_server_proxy, [state.resp], :diag, self(), state.namespace)
    {:reply, :ok, state}
  end

  def handle_call({:send_raw, payload}, _from, state) do
    send_request(state, payload)
    {:reply, :ok, state}
  end

  def send_request(state, payload) do
    Logger.info "send_request: #{inspect payload}"
    <<payload_int::integer-size(64)>> = payload
    SignalServerProxy.publish(state.signal_server_proxy, [{state.req, payload_int}], :diag_write, state.namespace)
  end

  @flow_type 0x3
  @flow_continue 0

  @flow_request_all_frames 0

  def resp_flow(state, flow_command, nbr_frames, delay \\ 0)

  #delay_in_millies [0..127]
  def resp_flow(state, flow_command, @flow_request_all_frames, separation_in_millies) do
    send_request(state, <<@flow_type::size(4), flow_command::size(4), @flow_request_all_frames::size(8), separation_in_millies::size(8), 0::size(40)>>)
  end

  #delay in micros according to standard
  def resp_flow(state, flow_command, nbr_frames, delay_in_micros) do
    send_request(state, <<@flow_type::size(4), flow_command::size(4), nbr_frames::size(8), get_code_for_delay(delay_in_micros)::size(8), 0::size(40)>>)
  end

  @doc ~S"""
    iex> Diagnostics.get_code_for_delay(100)
    0xF1
  """
  def get_code_for_delay(micro_delay) do
    delay =
    case micro_delay do
      0 -> 0xF1
      _ -> 0xF0 + div(micro_delay, 100)
    end
    case (micro_delay>900) do
      true -> 0xF9
      _ -> delay
    end
  end

  @single 0
  @first 1
  @consecutive 2
  @flow 3

  def handle_cast({:signal, msg}, state) do
    msg.name_values
    |> Enum.map(fn {_, value} ->
      Logger.info("Received from #{state.resp} value 0x#{Integer.to_string(value, 16)} decimal #{value}")

      <<flow::size(4), _rem::size(60)>> = <<value::size(64)>>
      case state.flow_mode do
        [flow_mode: :auto] ->
          case flow do
            @single ->
              <<_::size(4), size::size(4), _::size(56)>> = <<value::size(64)>>
              size_bits = size * 8
              rem_size = 56-size_bits
              <<_::size(4), size::size(4), payload::size(size_bits), _::size(rem_size)>> = <<value::size(64)>>
              Logger.info "single frame, number of bytes is size: #{size}, payload is #{inspect <<payload::size(size_bits)>>}"
            @first -> Logger.info "first frame"
              <<_::size(4), size::size(12), payload::size(48)>> = <<value::size(64)>>
              Logger.info "remeber first few bytes correspond to the query you made."
              Logger.info "first frame, number of bytes is size: #{size}, payload is #{inspect <<payload::size(48)>>}"
              # for demo purpose split the message in smaller chunks if possible
              # case size > 16 do
              #   true -> resp_flow(state, @flow_continue, 2, 900)
              #   _ -> resp_flow(state, @flow_continue, @flow_request_all_frames, 10)
              # end
              # resp_flow(state, @flow_continue, 2, 100)
              # resp_flow(state, @flow_continue, @flow_request_all_frames, 10)
              # :timer.sleep(10)
              # send_request(state, <<0x3, 0x22, 0xf1, 0x90, 0 ,0 ,0 ,0>>)
              resp_flow(state, @flow_continue, @flow_request_all_frames)
              # resp_flow(state, @flow_continue, 3, 100)
            @consecutive -> Logger.info "consecutive frame"
              <<_::size(4), index::size(4), payload::size(56)>> = <<value::size(64)>>
              Logger.info "consecutive frame, index is: #{index}, payload is #{inspect <<payload::size(56)>>}"
              # resp_flow(state, @flow_continue, @flow_request_all_frames)
              # resp_flow(state, @flow_continue, 3, 100)
              # send_request(state, <<0x3, 0x22, 0xf1, 0x90, 0 ,0 ,0 ,0>>)
            @flow -> Logger.info "flow frame"
              <<_::size(4), _::size(4), block_size::size(8), st::size(8)>> = <<value::size(64)>>
              Logger.info "flow frame, block size: #{inspect block_size}, ST is #{inspect <<st::size(8)>>}"
            _ -> Logger.info "not expected #{flow}"
          end
        _ -> Logger.info "manual flow control, match is #{inspect state.flow_mode}"
      end
      # Logger.info("size is #{size}, payload is #{inspect payload}")

    end)
    {:noreply, state}
  end

end
