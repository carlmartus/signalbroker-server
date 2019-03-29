defmodule AppSignalBase do
  use Supervisor

  def start_link({namespace, signal_base, signal_read_cache}) do
    name = make_name(namespace, "app")
    Supervisor.start_link(__MODULE__, {namespace, signal_base, signal_read_cache}, name: name)
  end

  def init({namespace, signal_base, signal_read_cache}) do
    children =
      case signal_read_cache do
        :not_needed ->
          [worker(SignalBase, [signal_base, namespace, signal_read_cache])]
        _ ->
          [
            worker(SignalBase, [signal_base, namespace, signal_read_cache]),
            worker(VirtualSignalReadCache, [signal_read_cache, signal_base])
          ]
      end

    Util.Config.app_log("Starting signal base `#{inspect signal_base}`")
    supervise(children, strategy: :one_for_one)
  end

  defp make_name(device, type),
    do: String.to_atom(Atom.to_string(device)<>"_"<>type)
end
