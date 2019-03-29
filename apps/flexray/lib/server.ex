defmodule FlexRay.Server do

  use GenServer
  require Logger

  defmodule State, do: defstruct [
    :addr,
    :port,
    :socket,
    :signal_pid,
    reconnect_intervall: 4_000,
    buffer_message: "",
    name: ""
  ]

  # CLIENT

  def start_link({name, signal_pid, addr, port}),
    do: GenServer.start_link(__MODULE__, {
      name, signal_pid,
      addr, port,
    }, name: name)

  # def connect(pid),
  #   do: GenServer.cast(pid, {:connect})

  # SERVER

  def init({name, signal_pid, addr, port}) do
    state = %State{addr: addr, port: port, name: name, signal_pid: signal_pid, buffer_message: ""}
    # connect(self)
    Process.send(self(), {:connect}, [:noconnect])
    {:ok, state}
  end


  def handle_info({:connect}, state) do
    case :gen_tcp.connect(state.addr, state.port, [:binary, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info "Successfully connected to flexray node on ip #{inspect state.addr}, port #{inspect state.port}"
        {:noreply, %State{state | socket: socket}}
      _ ->
        Logger.info "Failed to connect to flexray node in ip #{inspect state.addr}, port #{inspect state.port}"
        # retry
        Process.send_after(self(), {:connect}, state.reconnect_intervall)
        {:noreply, %State{state | socket: nil}}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Process.send(self(), {:connect}, [:noconnect])
    {:noreply, state}
  end

  def disconnect(pid) do
    GenServer.cast(pid, {:disconnect})
  end

  defp now(), do: System.system_time(:microsecond)

  defp parse_and_run(_state, <<>>, _fun) do
    <<>>
  end

  defp parse_and_run(state, bin, fun) do
    case byte_size(bin) > 10 do
      true ->
        <<_magic ::size(16), _flags::size(32), sid, cycle, data_size, _reserved, payload :: binary>> = bin
        case byte_size(payload) >= data_size do
          true ->
            bit_count = data_size * 8
            <<message_payload::size(bit_count), rest :: binary>> = payload
            fun.(state, sid, cycle, <<message_payload::size(bit_count)>>)
            parse_and_run(state, rest, fun)
          false ->
            # leftovers
            bin
        end
      false ->
        # leftovers
        bin
    end
  end

  defp dispatch_payload(state, sid, cycle, payload) do
    GenServer.cast(state.signal_pid, {:raw_flexray_frame, {sid, cycle}, payload, state.name, now()})
  end

  # this is where we get messages which we dispatch to the web client (socket)
  def handle_info({:tcp, _port, message}, state) do
    concat_message = state.buffer_message <> message;

    remaining = parse_and_run(state, concat_message, &dispatch_payload/4)
    {:noreply, %State{state | buffer_message: remaining}}
  end
end
