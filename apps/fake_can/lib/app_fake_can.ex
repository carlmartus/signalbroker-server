defmodule AppFakeCan do
  use Supervisor
  require Logger

  @moduledoc """
  CAN application using (ng_can)[https://github.com/johnnyhh/ng_can].

  Can send and recieve CAN frames.
  """

  @doc """
  Start a supervised CAN-bus device app.
  ```
  iex>
  AppNgCan.start_link("can0", human_file: "configuration/human_files/cfile.json")
  {:ok, pid(0,121,0)}
  ```
  """
  def start_link(device, recorded_file, descriptions) do
    name = make_name(device, "app")
    Supervisor.start_link(__MODULE__, {device, descriptions, recorded_file}, name: name)
  end

  @doc """
  AppNgCan.start_link("can0", human_file: "configuration/human_files/cfile.json")
  """
  # def start_bil01 do
  #   AppNgCan.start_link("can0", human_file: "configuration/human_files/cfile.json")
  # end
  #
  # @doc """
  # AppNgCan.start_link("vcan0", human_file: "configuration/human_files/cfile.json")
  # """
  # def start_simulation do
  #   AppNgCan.start_link("vcan0", human_file: "configuration/human_files/cfile.json")
  # end


  def init({device, descriptions, recorded_file}) do
    desc = make_name(device, "desc") # CanDescriptions process name
    conn = make_name(device, "conn") # CanConnector
    signal = make_name(device, "signal") # CanSignal

    children = [
      worker(Payload.Signal, [signal, conn, desc]),
      worker(Payload.Descriptions, [desc, signal, descriptions]),
      worker(FakeCanConnection, [conn, signal, recorded_file]),
    ]
    supervise(children, strategy: :one_for_one)
  end

  defp make_name(device, type),
    do: String.to_atom("can_"<>device<>"_"<>type)
end
