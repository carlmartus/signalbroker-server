defmodule UnixDS.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = Util.Config.get_config()
    UnixDS.Supervisor.start_link(config.gateway.gateway_pid)
  end


  @doc """
  Get unique name for client process.
  @param pid PID of client socket owner.
  """
  def get_client_name(id),
    do: get_name("client_#{id}")

  def get_name(name),
    do: String.to_atom("unixds_" <> name)
end
