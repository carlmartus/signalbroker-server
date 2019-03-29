defmodule UnixDS.Timeout do
  use GenServer

  @moduledoc """
  Signals a UnixDS client whenever a timeout has been reached.
  """

  # CLIENT
  # ======

  @doc """
  Create instance. Will not start automatically. Call `activate` to start.
  `target` is the pid that will be called with GenServer cast message
  `:timeout`.
  """
  def start_link({name, target}) do
    GenServer.start_link(__MODULE__, target, name: name)
  end

  @doc "Start timeout detector with timeout in miliseconds"
  def activate(pid, millis) do
    GenServer.cast(pid, {:activate, millis})
  end

  def deactivate(pid) do
    GenServer.cast(pid, :deactivate)
  end


  # SERVER
  # ======

  def init(target), do: {:ok, target}
  def handle_cast({:activate, millis}, target) do
    if millis > 0 do
      {:noreply, target, millis}
    else
      {:noreply, target}
    end
  end

  def handle_cast(:deactivate, target) do
    {:noreply, target}
  end

  def handle_info(:timeout, target) do
    GenServer.cast(target, :timeout)
    {:noreply, target}
  end
end
