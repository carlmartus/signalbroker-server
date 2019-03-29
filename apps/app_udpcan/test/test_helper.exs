ExUnit.start()

defmodule Helper.UdpClient do
  @moduledoc """
  Simple UDP client for unit testing.

  Parent pid is used to signal a received UDP packet.
  """

  use GenServer

  defmodule State, do: defstruct [:parent_pid, :socket, :dest_port, received: []]

  def start_link(listen_port, dest_port),
    do: GenServer.start_link(__MODULE__, {listen_port, dest_port, self()})

  def init({listen_port, dest_port, parent_pid}) do
    {:ok, socket} = :gen_udp.open(listen_port, [:binary])
    {:ok, %State{parent_pid: parent_pid, socket: socket, dest_port: dest_port}}
  end

  def send_data(pid, data), do: GenServer.call(pid, {:send, data})
  def handle_call({:send, data}, _, state) do
    :gen_udp.send(state.socket, {127, 0, 0, 1}, state.dest_port, data)
    {:reply, :ok, state}
  end

  def handle_info({:udp, _, _, _, data}, state) do
    state = %State{state | received: [data | state.received]}
    send state.parent_pid, {:helper_udp, data}
    {:noreply, state}
  end
end
