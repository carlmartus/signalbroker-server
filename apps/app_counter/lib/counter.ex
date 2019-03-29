defmodule Counter do
  use GenServer
  require Logger

  defmodule Stats, do: defstruct [
    signals: 0,
    frames: 0,
  ]

  defmodule State, do: defstruct [
    listeners: [],
    stats: %Stats{},
  ]

  # CLIENT

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def swap(), do: GenServer.cast(__MODULE__, :swap)
  def tick_signal(count \\ 1), do: GenServer.cast(__MODULE__, {:tick, :signals, count})
  def tick_frame(count \\ 1), do: GenServer.cast(__MODULE__, {:tick, :frames, count})
  def add_listen(pid), do: GenServer.cast(__MODULE__, {:listen, pid})

  @doc """
  Output results to a `.csv` file.
  """
  def install_csv_writer(delete_old, path \\ "/tmp/counter.csv") do
    if(delete_old, do: File.rm(path))

    {:ok, p} = res = Counter.CSV.start_link(path)
    add_listen(p)
    res
  end

  defdelegate force_tick, to: Counter.Timer

  # SERVER

  def init(_) do
    {:ok, %State{}}
  end

  def handle_cast(:swap, state) do
    Enum.map(state.listeners, fn pid ->
      GenServer.cast(pid, {:counter_stats, state.stats})
    end)
    {:noreply, %State{state| stats: %Stats{}}}
  end

  def handle_cast({:tick, field, count}, state) do
    {_, new_stats} = Map.get_and_update(state.stats, field, fn cur ->
      {cur, cur+count}
    end)

    {:noreply, %State{state| stats: new_stats}}
  end

  def handle_cast({:listen, pid}, state) do
    listeners = [pid | state.listeners]
    {:noreply, %State{state| listeners: listeners}}
  end
end
