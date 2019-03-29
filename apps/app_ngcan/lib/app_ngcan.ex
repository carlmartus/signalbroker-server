defmodule AppNgCan do
  use Supervisor

  @moduledoc """
  CAN application using (ng_can)[https://github.com/johnnyhh/ng_can].

  Can send and recieve CAN frames.
  """

  def start_link({{device, desc, conn, signal, canwriter, cache, signalbase, namespace, type}, physical}) when is_atom(namespace)  do
    name = Payload.Name.generate_name_from_namespace(namespace, :supervisor)

    Util.Config.app_log("Starting ngcan `#{inspect name}`")

    Supervisor.start_link(
      __MODULE__,
      {{device, desc, conn, signal, canwriter, cache, signalbase, type}, physical},
      name: name)
  end

  @doc """
  Start a supervised CAN-bus device app.
  Warning. This function is deprecated.

    iex> AppNgCan.start_link("can0", human_file: "configuration/human_files/cfile.json")
    {:ok, pid(0,121,0)}

  The second parameter can also by the physical field from a config.exs.
  """
  # def start_link(device, signal_base, physical) do
  #   AppNgCan.start_link({{
  #     device,
  #     make_name(device, "desc"),
  #     make_name(device, "conn"),
  #     make_name(device, "signal"),
  #     make_name(device, "canwriter"),
  #     signal_base}, physical})
  # end

  def init({{device, desc, conn, signal, canwriter, cache, signalbase, type}, physical}) do
    children = [
      worker(Payload.Cache, [{cache, desc, signal}]),
      worker(Payload.Writer, [{canwriter, conn, desc, signal, cache, signalbase, type}]), #this must be started before CanDesciptions....
      worker(Payload.Signal, [{signal, conn, desc, cache, canwriter, signalbase, type}]),
      worker(Payload.Descriptions, [{desc, signal, physical, canwriter}]),
      worker(CanConnector, [{conn, signal, device}]),
    ]
    supervise(children, strategy: :one_for_one)
  end

end
