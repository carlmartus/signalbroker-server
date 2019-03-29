defmodule Debug.Route.Ets do
  use GenServer

  defmodule State, do: defstruct [:ets_db]

  # CLIENT

  def start_link(name),
    do: GenServer.start_link(__MODULE__, name, name: name)

  def reg(pid, name, target),
    do: GenServer.call(pid, {:reg, name, target})

  def pub(pid, name, value),
    do: GenServer.cast(pid, {:pub, name, value})

  # SERVER

  def init(name) do
    db_name = String.to_atom("#{name}_ets")

    state = %State{
      ets_db: :ets.new(db_name, [:set]),
    }
    {:ok, state}
  end

  def handle_call({:reg, name, target}, _, state) do
    :ets.insert(state.ets_db, {name, target})
    {:reply, :ok, state}
  end

  # Does this even work? {:signal ...} is not suppose to look like that.
  def handle_cast({:pub, name, value}, state) do
    case :ets.lookup(state.ets_db, name) do
      [] -> :none
      targets -> Enum.map(targets, fn({_, target}) ->
        GenServer.cast(target, {:signal, name, value})
      end)
    end

    {:noreply, state}
  end
end
