defmodule Lin.ConfigRouter do
  use GenServer;

  defstruct [
    :config,
  ]

  def start_link({name, port, config}) do
    GenServer.start_link(__MODULE__, {port, config}, name: name)
  end

  def parse_ids_and_sizes(pid),
    do: GenServer.cast(pid, {:parse_ids_and_sizes})

  #Server

  def init({port, config}) do
    {:ok, socket} = :gen_udp.open(port, [:binary, reuseaddr: true])
    {:ok, %__MODULE__{config: config}}
  end

  require Logger
  require Lin.ArduinoConfig
  @header Lin.ArduinoConfig.header



  # just forward request to propriate config server
  def handle_info({:udp, _, _, _, <<@header, rib_id, _hash::size(16), identifier, payload::binary>>} = request, state) do
    case Map.get(state.config, rib_id) do
      nil ->
        Logger.warn("is your rib_id avaliable in your interfaces file? Configuration requested for unknown rib_id #{inspect rib_id} identifier is: #{inspect identifier} payload is: #{inspect payload}")
        nil
      dest_pid ->
        GenServer.cast(dest_pid, request)
    end
    {:noreply, state}
  end

  def handle_info({:udp, _, _, _, data}, state) do
    Logger.warn "Warning! don't understand UDP/LIN message: #{inspect data} on port #{inspect state.config}. Likely version missmatch"
    {:noreply, state}
  end

end
