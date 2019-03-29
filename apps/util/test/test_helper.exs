ExUnit.start()

defmodule AsynchronousCaller do
  use GenServer

  # CLIENT

  def start_link(),
    do: GenServer.start_link(__MODULE__, nil)

  def trigger(pid, data),
    do: GenServer.cast(pid, {:trigger, data})

  # SERVER

  def init(_), do: {:ok, nil}

  def handle_cast({:trigger, data}, state) do

    :timer.sleep(4) # Do some work! Take a nap :)

    if Util.Config.is_test() do
      Util.Forwarder.send(data)
    end

    {:noreply, state}
  end
end
