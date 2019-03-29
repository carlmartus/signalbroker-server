defmodule UnixDS.Server do
  use GenServer

  defstruct [
    :socket,
    :name_clientholder
  ]

  @moduledoc """
  Intefrace to Core system through a Unix domain socket.
  """

  # CLIENT

  def start_link({name, name_clientholder, path, gateway}),
    do: GenServer.start_link(__MODULE__, {path, name_clientholder, gateway}, name: name)

  def start_loop(pid, gateway),
    do: GenServer.cast(pid, {:start_loop, gateway})

  # SERVER
  def init({path, name_clientholder, gateway}) do
    File.rm(path)
    Path.dirname(path) |> File.mkdir

    {:ok, socket} = :gen_tcp.listen(0, [
      :binary,
      ip: {:local, path},
      packet: 2,
      active: false,
      reuseaddr: true])
      File.chmod(path, 0o777)

    start_loop(self(), gateway)
    {:ok, %__MODULE__{socket: socket, name_clientholder: name_clientholder}}
  end

  def handle_cast({:start_loop, gateway}, state) do
    loop(state, gateway)
    {:stop, :normal, state}
  end

  defp loop(state, gateway, counter \\ 1) do
    case :gen_tcp.accept(state.socket) do
      {:ok, conn} ->

        client_name = UnixDS.Application.get_client_name(counter)
        {:ok, _} = UnixDS.ClientHolder.start_client(
          state.name_clientholder, conn, client_name, gateway)

        # Transfer process event signaling to client
        :gen_tcp.controlling_process(conn,  Process.whereis(client_name))
        :inet.setopts(conn, active: true)

        loop(state, gateway, counter+1)
    end
  end
end
