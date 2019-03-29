defmodule CanConnector do
  use GenServer
  require Logger

  defstruct [
    :name,
    :can_port,
    :signal_pid,
  ]

  # CLIENT

  @doc """
  Start a CAN-device interface.
   * `name` name to give the process.
   * `signal_pid` Reference to `CanSignal` to send frames.
   * `interface` name of the device.
  """
  def start_link({name, signal_pid, interface}),
    do: GenServer.start_link(__MODULE__, {name, interface, signal_pid}, name: name)

  def stop(), do: GenServer.stop(__MODULE__)

  # SERVER

  def init({name, interface, signal_pid}) do
    #Logger.info "trying to open #{inspect interface}"
    case Ng.Can.start_link do
      {:ok, can_port} ->
        _result = Ng.Can.open(can_port, interface, [sndbuf: 1024, rcvbuf: 106496])
        Ng.Can.await_read(can_port)
        {:ok, %__MODULE__{name: name, can_port: can_port, signal_pid: signal_pid}}
      {:error, message} -> Logger.debug "Failed to start #{inspect message}"
        {:error, message}
    end
  end

  @doc """
  WARNING, not tested!
  """
  def handle_call({:send_message, message}, _from, {can_port, _callback} = state) do
    result = Ng.Can.write(can_port, message)
    #Logger.info "dispatched on can #{inspect message} with result #{result}"
    {:reply, result, state}
  end

  def handle_cast({:write, can_id, payload}, state) do
    Ng.Can.write(state.can_port, {can_id, payload})
    {:noreply, state}
  end

  def handle_info({:can_frames, _interface_name, recvd_frames}, state) do
    Payload.Signal.handle_raw_can_frames(state.signal_pid, state.name, recvd_frames)
    Ng.Can.await_read(state.can_port)
    {:noreply, state}
  end
end
