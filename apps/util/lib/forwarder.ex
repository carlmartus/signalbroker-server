defmodule Util.Forwarder do
  use GenServer

  @moduledoc """
  Unit tester *Forwarder* as described here:
  <http://openmymind.net/Testing-Asynchronous-Code-In-Elixir/>
  """

  # CLIENT

  def start_link(),
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def start_link(pid),
    do: GenServer.start_link(__MODULE__, pid, name: __MODULE__)

  def terminate(),
    do: GenServer.stop(__MODULE__)

  @doc """
  Called at the start of each test to set the current process id.
  """
  def setup(pid) do
    GenServer.cast(__MODULE__, {:setup, pid})
  end

  @doc "Used to send a message to a test."
  def send(msg) do
    GenServer.cast(__MODULE__, {:send, msg})
  end

  def receive() do
    receive do
      msg -> msg
    after
      100 -> raise("Nothing received")
    end
  end

  # SERVER

  def init(pid) do
    {:ok, pid}
  end

  @doc "Store the current pid as our state."
  def handle_cast({:setup, pid}, _state) do
    {:noreply, pid}
  end

  @doc "Send the message to the test."
  def handle_cast({:send, msg}, pid) do
    send(pid, msg)
    {:noreply, pid}
  end
end
