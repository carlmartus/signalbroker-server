defmodule CanUdp.Server do
  @moduledoc """
  UDP CAN connection to a VIU board with CAN interfaces.
  Receives and sends CAN frames in a UDP format.

  ## How?
  This process creates a server.
  Then when the first UDP packet is received, the address of the sender is set as the destination.
  Subsequently, all messages being send (see. `send_frame`) through this module is targeted towards that destination.
  """

  use GenServer
  require Mix

  defmodule State, do: defstruct [
    :name_pid, :signal_pid, :socket,
    :target_host, :target_port,
  ]

  # CLIENT

  def start_link({name, signal_pid, server_port, target_host, target_port}),
    do: GenServer.start_link(__MODULE__, {
      name, signal_pid,
      server_port, target_host, target_port,
    }, name: name)

  def write(pid, frame_id, frame_payload),
    do: GenServer.cast(pid, {:write, frame_id, frame_payload})

  # specifically useful for lin auto config nodes, where host adress is unavalibel
  def provide_host_adress(pid, host_ip),
    do: GenServer.cast(pid, {:host_adress, host_ip})

  # SERVER

  def init({name_pid, signal_pid, server_port, target_host, target_port}) do
    {:ok, socket} = :gen_udp.open(server_port, [:binary, reuseaddr: true])

    state = %State{
      name_pid: name_pid,
      socket: socket,
      signal_pid: signal_pid,
      target_host: target_host,
      target_port: target_port,
    }

    {:ok, state}
  end

  def handle_cast({:host_adress, host_ip}, state) do
    {:noreply, %State{state | target_host: host_ip}}
  end

  def handle_info({:udp, _, _, _, data}, state) do
    handle_packet(data, state)
    {:noreply, state}
  end

  require Logger

  def handle_cast({:write, frame_id, frame_payload}, state) do
    # Logger.debug("write data, #{inspect frame_id} #{inspect frame_payload}")
    send_data(frame_id, frame_payload, state)
    {:noreply, state}
  end

  # lin specific
  def handle_cast({:write_arbitration_frame, frame_id, frame_length}, state) do
    # Logger.debug("write data, #{inspect frame_id} #{inspect frame_payload}")
    if(Util.Config.is_test(),
       do: Util.Forwarder.send({:write_arbitration_frame, frame_id, frame_length}))

    send_arbritration_frame(frame_id, frame_length, state)
    {:noreply, state}
  end

  # Just for testing
  if Mix.env() == :test do
    def handle_call(:get_state, _, state), do: {:reply, state}
    def get_state(pid), do: GenServer.call(pid, :get_state)
  end

  # INTERNAL

  defp handle_packet(data, state) do
    frames = CanUdp.parse_udp_frames(data)
    Payload.Signal.handle_raw_can_frames(state.signal_pid, state.name_pid, frames)
  end

  defp send_data_wrapper(socket, host, port, data) do
    case host do
      nil -> Logger.warn "Missing dest_ip, not able to send data intended for #{inspect port}"
      _ ->
        :gen_udp.send(socket, host, port, data)
    end
  end

  defp send_data(frame_id, frame_payload, state) do
    data = CanUdp.make_udp_frame(frame_id, frame_payload)
    send_data_wrapper(state.socket, state.target_host, state.target_port, data)
  end

  defp send_arbritration_frame(frame_id, expected_bytes_in_response, state) do
    data = CanUdp.make_udp_frame_size(frame_id, expected_bytes_in_response)
    send_data_wrapper(state.socket, state.target_host, state.target_port, data)
    #Logger.debug "Sending udp frame_id #{inspect frame_id} #{inspect data}"
  end
end
