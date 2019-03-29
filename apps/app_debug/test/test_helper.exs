ExUnit.start()

defmodule Debug.Route.PingPong do
  use GenServer

  def start_link(target, message),
    do: GenServer.start_link(__MODULE__, {target, message})

  def init(state), do: {:ok, state}

  def handle_cast({:signal, _name, _value}, {target, message}=state) do
    GenServer.cast(target, message)
    {:noreply, state}
  end
end
