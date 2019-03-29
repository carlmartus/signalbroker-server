defmodule Counter.Timer do
  use GenServer

  @timeout 1_000

  # CLIENT

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def force_tick(), do: GenServer.cast(__MODULE__, :force_tick)

  # SERVER

  def init(:ok), do: {:ok, :nothing, @timeout}

  def handle_cast(:force_tick, state) do
    send_swap()
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, state) do
    send_swap()
    {:noreply, state, @timeout}
  end

  # INTERNAL

  defp send_swap(), do: Counter.swap()
end
