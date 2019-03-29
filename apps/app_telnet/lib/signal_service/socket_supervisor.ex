defmodule SocketSupervisor do
  use Supervisor
  require Logger

  def start_link(arg) do
    name = SocketSupervisor.Supervisor
    Logger.info "Starting TCP socket `#{inspect name}`"
    Supervisor.start_link(__MODULE__, arg, name: name)
  end

  def init(_arg) do
    supervise [worker(SocketHolder, [], restart: :transient)], strategy: :simple_one_for_one
  end
end
