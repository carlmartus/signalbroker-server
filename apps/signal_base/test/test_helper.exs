ExUnit.start()

defmodule Helper.SignalCatcher do
  use GenServer
  require Logger

  defstruct [latest: nil, counter: 0]

  # CLIENT
  def start_link(), do: GenServer.start_link(__MODULE__, %__MODULE__{})

  # SERVER
  def init(state), do: {:ok, state}

  def handle_cast({:execute, cb}, state) do
    cb.()
    {:noreply, state}
  end
  def handle_cast(msg, st), do: {:noreply, tick_state(st, msg)}
  def handle_call(:get_state, _, state), do: {:reply, state.latest, state}
  def handle_call(:get_counter, _, state), do: {:reply, state.counter, state}
  def handle_call(:reset_counter, _, _state), do: {:reply, nil, %__MODULE__{}}
  def handle_call(msg, _, st), do: {:reply, :ok, tick_state(st, msg)}

  # INTERNAL
  defp tick_state(st, msg), do:
  %__MODULE__{st| latest: msg, counter: st.counter+1}
end

defmodule Helpers do
  def close_process(p), do: :ok = GenServer.stop(p, :normal)
  def close_processes(pids), do: pids |> Enum.map(&close_process/1)
end
