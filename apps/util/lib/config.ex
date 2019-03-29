defmodule Util.Config do
  use GenServer
  require Logger

  # CLIENT

  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: __MODULE__)
  end

  def start_link(path, pid) do
    GenServer.start_link(__MODULE__, path, name: pid)
  end

  def get_config() do
    GenServer.call(__MODULE__, :get_config)
  end

  def get_config(pid) do
    GenServer.call(pid, :get_config)
  end

  def is_test() do
    Application.get_env(:util, :is_test)
  end

  @doc """
  Converts a IP-4 address to a tuple compatible with `:gen_udp` and `:gen_tcp`.
  """
  def parse_ip_string(str) do
    to_charlist(str)
  end

  @doc """
  Log a message that doesn't show up during testing
  """
  def app_log(msg) do
    if !is_test() do
      Logger.info(msg)
    end
  end

  # SERVER

  def init(path) do
    _config =
      path
      |> File.read()
      |> case do
        {:ok, content} ->
          config =
            content
            |> Poison.decode!(keys: :atoms)
            |> refine()
          {:ok, config}
        {:error, reason} ->
          {:stop, "Can't open configuration file (#{path}) reason: #{inspect reason}"}
      end
  end

  def handle_call(:get_config, _, config) do
    {:reply, config, config}
  end

  # Change some fields from strings to atoms
  defp refine(config) do
    # Change gateway from a string to an Atom
    new_gateway = %{config.gateway | gateway_pid: String.to_atom(config.gateway.gateway_pid)}

    # Return with updated fields
    %{config | gateway: new_gateway}
  end
end
