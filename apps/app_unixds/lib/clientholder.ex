defmodule UnixDS.ClientHolder do
  use Supervisor

  def start_link(name),
    do: Supervisor.start_link(__MODULE__, [], name: name)

  def start_client(pid, client, name, gateway) do
    Supervisor.start_child(pid, [{name, client, gateway}])
  end

  def init([]),
    do: Supervisor.init([UnixDS.ClientCouple], strategy: :simple_one_for_one)
end

defmodule UnixDS.ClientCouple do
  use Supervisor

  def start_link(_sup_opts, params),
    do: Supervisor.start_link(__MODULE__, params)

  def init({name, socket, gateway}) do
    timeout_name = String.to_atom("#{name}_timeout")

    Supervisor.init([
      {UnixDS.Client, {name, socket, gateway, timeout_name}},
      {UnixDS.Timeout, {timeout_name, name}},
    ], strategy: :one_for_all)
  end
end
