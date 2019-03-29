defmodule PeriodicalHammer do

  use GenServer;
  require Logger;

  defstruct [
    function: nil,
    intervall_in_ms: 0,
    name: ""
  ]

  #Client

  defp start_link_internal(signal_hammer_pid, function, intervall_in_ms) do
    state = %__MODULE__{function: function, intervall_in_ms: intervall_in_ms, name: signal_hammer_pid}
    GenServer.start_link(__MODULE__, state, name: signal_hammer_pid)
  end

  defp unique_name(name) do
    # create unique name in some way if needed....
    String.to_atom(name)
  end

  def start_link(name, function, frequency) do
    signal_hammer_pid = unique_name(name)

    case Process.whereis(signal_hammer_pid) do
      nil ->
        case frequency do
          0 -> :one_shot
          _ ->
            start_link_internal(signal_hammer_pid, function, round(1000/frequency))
            :running
        end
      _ ->
        update(signal_hammer_pid, function, frequency)
    end

  end

  defp stop(name) do
    # Logger.debug "Stop hammer for name: #{inspect name}"
    GenServer.stop(name)
  end

  def update(signal_hammer_pid, function, 0) do
    stop(signal_hammer_pid)
    :stopping
  end

  def update(signal_hammer_pid, function, frequency) do
    GenServer.cast(signal_hammer_pid, {:update, function, frequency})
    :running
  end

  #Server
  def init(state) do
    schedule_work(state.intervall_in_ms)
    {:ok, state}
  end

  defp schedule_work(intervall_in_ms),
    do: Process.send_after(self(), :work, intervall_in_ms)

  def handle_info(:work, state) do
    schedule_work(state.intervall_in_ms)
    state.function.()
    {:noreply, state}

  end
  def handle_cast({:update, function, frequency}, state) do
    # Logger.info "update called #{inspect self()} #{inspect state.name}"
    state = %__MODULE__{state | function: function, intervall_in_ms: round(1000/frequency)}
    {:noreply, state}
  end

end
