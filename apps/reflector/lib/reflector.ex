defmodule Reflector do
  use GenServer

  defstruct [
    source: nil,
    dest: nil,
    source_id: nil,
    proxy: nil,
    name: nil,
    common_source_identifier: nil,
    exclude_frames: []
  ]

  def start_link({namespace_source, namespace_dest, name, common_source_identifier, exclude_frames, proxy}) do
    GenServer.start_link(__MODULE__, {namespace_source, namespace_dest, common_source_identifier, exclude_frames, proxy, name}, name: name)
  end

  def init({source, dest, common_source_identifier, exclude_frames, proxy, name}) do
    state = %__MODULE__{source: source, dest: dest, source_id: common_source_identifier, proxy: proxy, exclude_frames: exclude_frames, name: name, common_source_identifier: common_source_identifier}
    start_reflect(state)
    {:ok, state}
  end

  # this is a slightly crazy hack - names should only be generated in one place
  # defp generate_pid_from_namespace(namespace, suffix) do
  #   config = Util.Config.get_config()
  #   [chain] =
  #     config.chains
  #     |> Enum.filter(fn(conf) ->
  #       conf.router.namespace == Atom.to_string(namespace)
  #     end)
  #
  #   case chain.physical.type do
  #     "can" -> AppNgCan.Application.make_name(chain.physical.device_name, suffix)
  #     "udp" -> CanUdp.App.make_name(chain.physical.device_name, suffix)
  #   end
  # end

  defp start_reflect(state) do
    frames = SignalServerProxy.get_channels_by_tag_and_listen_for_events(state.proxy, :frame, self(), state.source)

    if (Enum.count(frames) != 0) do
      desc_pid = Payload.Name.generate_name_from_namespace(state.source, :desc)
      signal_pid = Payload.Name.generate_name_from_namespace(state.source, :signal)
      dest_conn_pid = Payload.Name.generate_name_from_namespace(state.dest, :server)

      exclude_id = Enum.map(state.exclude_frames, fn(signal) ->
        case Payload.Descriptions.get_field_by_name(desc_pid, signal) do
          nil ->
            []
          field -> field.id
        end
      end)

      reflect = fn(raw_frames, _) ->
        Enum.each(raw_frames, fn {can_id, payload} ->
          case Enum.member?(exclude_id, can_id) do
            true -> []
            false ->
              Payload.Interface.write(dest_conn_pid, can_id, payload)
          end
        end)
      end

      Payload.Signal.set_run_hook_on_input_frame(signal_pid, reflect)
    end
  end

  def handle_cast({:signal_server_updated}, state) do
    start_reflect(state)
    {:noreply, state}
  end


  def handle_cast({:signal, msg}, state) do
    SignalServerProxy.publish(state.proxy, msg.name_values, state.source_id, state.dest)
    {:noreply, state}
  end
end
