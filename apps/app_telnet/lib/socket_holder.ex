defmodule SocketHolder do
  # @interval 1000
  use GenServer
  require Logger

  # schema to validate client call
  # TODO we do not know how much this affects performance.
  read_sub_unsub_schema = %{
    "type" => "object",
    "required" => ["command", "signals"],
    "properties" => %{
      "command" => %{
        "type" => "string"
        },
        "namespace" => %{
          "type" => "string"
        },
        "signals" => %{
          "type" => "array",
          "items" => %{
            "type" => "string"
          }
        }
    }
  } |> ExJsonSchema.Schema.resolve

  write_schema = %{
    "type" => "object",
    "required" => ["command", "signals"],
    "properties" => %{
      "command" => %{
        "type" => "string"
      },
      "namespace" => %{
        "type" => "string"
      },
      "signals" => %{
        "type" => "object",
        "properties" => %{
          "/" => %{}
        },
        "patternProperties" => %{
          "^.*$" => %{
            "anyOf" => [
              %{"type" => "integer"},
              %{"type" => "string"}
            ]
          }
        },
        "items" => %{
          "type" => "string",
        },
        "additionalProperties" => false,
      }
    }
  } |> ExJsonSchema.Schema.resolve

  defstruct [
    :socket,
    :signal_server_proxy,
    buffer_message: "",
    write_schema: write_schema,
    read_sub_unsub_schema: read_sub_unsub_schema
  ]

  ####
  # External API

  def start_link({socket, signal_server_proxy}) do
    GenServer.start_link(__MODULE__, {socket, signal_server_proxy})
  end

  #####
  # GenServer implementaion



  def init({socket, signal_server_proxy}) do
    Logger.info "Start SocketHolder pid: #{inspect self()} socket: #{inspect socket}"
    state =%__MODULE__{
      socket: socket,
      signal_server_proxy: signal_server_proxy}
    {:ok, state}
  end


  def handle_info({:tcp_closed, port}, state) do
    Logger.info "Stop subscription pid: #{inspect self()} socket: #{inspect state} message: #{inspect port}"
    SignalServerProxy.remove_listeners(state.signal_server_proxy, self())
    {:stop, :normal, state.socket}
  end

  defmodule Commands, do: defstruct [
    name: nil,
    num_args: 1,
    namespace: 1
  ]

  defp handle_lin(state, cmd) do
    Logger.debug "lin command #{cmd}"
    cmds = [%Commands{name: "list_buses"},
	    %Commands{name: "list_schedules", num_args: 2},
	    %Commands{name: "load_schedule", num_args: 3}, # load_schedule <namespace> schedule
	    %Commands{name: "load_schedule", num_args: 4}, # load_schedule <namespace> schedule num_repeats
	    %Commands{name: "start", num_args: 2},
	    %Commands{name: "stop", num_args: 2},
      %Commands{name: "wakeup", num_args: 3}]

    config = Util.Config.get_config()
    namespaces = Enum.map(Enum.filter(config.chains, fn(x) -> x.type == "lin" end), fn(x) -> x.namespace end)

    c2 =
      cmds
      |> Enum.filter(fn(x) ->
        (x.name == Enum.at(cmd, 0)) and (x.num_args == length(cmd)) and (x.num_args == 1 or Enum.at(cmd, x.namespace) in namespaces)
      end)

    if length(c2) == 1 do
      c = Enum.at(c2, 0)

      case c.name do
      	"list_buses" ->
      	  write_line(state.socket, {:ok, Poison.encode!(namespaces)})
      	  :ok
      	"list_schedules" ->
      	  schedule_file = Enum.at(Enum.filter(config.chains, fn(x) -> x.type == "lin" and x.namespace == Enum.at(cmd, c.namespace) end), 0).schedule_file

      	  l = Enum.map(Lin.Ldf.parse_file(schedule_file).scheduling, fn(x) -> x.table_name end)

      	  write_line(state.socket, {:ok, Poison.encode!(l)})

      	  :ok
      	"load_schedule" ->
      	  schedule_file = Enum.at(Enum.filter(config.chains, fn(x) -> x.type == "lin" and x.namespace == Enum.at(cmd, c.namespace) end), 0).schedule_file

      	  l = Enum.filter(Lin.Ldf.parse_file(schedule_file).scheduling, fn(x) -> x.table_name == Enum.at(cmd, 2) end)
      	  if length(l) == 1 do
      	    pid = Payload.Name.generate_name_from_namespace(Enum.at(cmd, c.namespace), :scheduler)

      	    num_repeats = if c.num_args == 4 do
      	      Enum.at(cmd, 3)
      	    else
      	      0
      	    end
      	    Lin.Scheduler.run_pattern(pid, schedule_file, Enum.at(cmd, 2), num_repeats)
      	    write_line(state.socket, {:ok, Poison.encode!(["ok"])})
      	    :ok
      	  else
      	    :error
      	  end
      	"start" ->
      	    pid = Payload.Name.generate_name_from_namespace(Enum.at(cmd, c.namespace), :scheduler)
      	    Lin.Scheduler.start_pattern(pid)
      	    write_line(state.socket, {:ok, Poison.encode!(["ok"])})
      	  :ok
      	"stop" ->
      	    pid = Payload.Name.generate_name_from_namespace(Enum.at(cmd, c.namespace), :scheduler)
      	    Lin.Scheduler.stop_pattern(pid)
      	    write_line(state.socket, {:ok, Poison.encode!(["ok"])})
      	  :ok
        "wakeup" ->
            add_namespace_and_execute(:publish, [state.signal_server_proxy, [{Enum.at(cmd, 2), :arbitration}], state.socket], Enum.at(cmd, c.namespace))
            write_line(state.socket, {:ok, Poison.encode!(["ok"])})
          :ok
      	_ ->
      	  :error
      end
    else
      :error
    end
  end

  def handle_info({:tcp, _port, message}, state) do
    concat_message = state.buffer_message <> message;

    pieces = String.split(concat_message, "\n")
    Enum.drop(pieces, -1)
    |> Enum.filter(fn(x) ->
      String.length(x) > 0
    end)
    |> Enum.map(fn(x) ->
      process_request({x}, state)
    end)
    [remaining] = Enum.take(pieces, -1)

    {:noreply, %__MODULE__{state | buffer_message: remaining}}
  end

  def package_response(request, response) do
    user_response =
     case request["userdata"] do
       nil -> nil
       data -> data
     end
    Map.merge(%{userdata: user_response}, response)
  end

  def validate_request(json_command, schema, fun, socket) do
    case ExJsonSchema.Validator.validate(schema, json_command) do
      :ok -> fun.()
      {:error, [message_tuple]} ->
        Logger.info "json payload incorrect: #{inspect message_tuple}"
        return = %{"error" => (inspect message_tuple)}
        write_line(socket, {:ok, Poison.encode!(return)})
    end
  end

  def process_request({message}, state) do
    case Poison.decode(message) do
      {:ok, json_command} ->
        # Logger.info "Received command #{json_command["command"]} pid: #{inspect self()} socket: #{inspect state} message: #{inspect message}"
        # Logger.info "Received command #{inspect json_command}"

      	if json_command["lin"] do
      	  handle_lin(state, json_command["lin"])
      	end

        case json_command["command"] do
          "get_configuration" ->
            Logger.debug "Requested configuration file"
            return = package_response json_command, %{configuration: SignalServerProxy.get_configuration(state.signal_server_proxy)}
            write_line(state.socket, {:ok, Poison.encode!(return)})
          "list" ->
            Logger.debug "about to list entries #{json_command["command"]}"
            json_signals =
              case json_command["tag"] do
                nil -> add_namespace_and_execute(:get_channels, [state.signal_server_proxy], json_command["namespace"])
                tag -> add_namespace_and_execute(:get_channels_by_tag, [state.signal_server_proxy, String.to_atom(tag)], json_command["namespace"])
              end
            return = package_response(json_command, %{signals: json_signals})
            write_line(state.socket, {:ok, Poison.encode!(return)})
          "subscribe" ->
            execute = fn() ->
              signals = json_command["signals"]
              if Enum.empty?(signals) do
                add_namespace_and_execute(:register_omnius_listener, [state.signal_server_proxy, state.socket, self()], json_command["namespace"])
              else
                add_namespace_and_execute(:register_listeners, [state.signal_server_proxy, signals, state.socket, self()], json_command["namespace"])
              end
              Logger.debug "subscribe pid: #{inspect self()}"
            end
            validate_request(json_command, state.read_sub_unsub_schema, execute, state.socket)
            :ok
          "unsubscribe" ->
            execute = fn() ->
              signals = json_command["signals"]
              Enum.map(signals, fn sig ->
                add_namespace_and_execute(:remove_listener, [state.signal_server_proxy, sig, self()], json_command["namespace"])
              end)
            end
            validate_request(json_command, state.read_sub_unsub_schema, execute, state.socket)
            :ok
          "write" ->
            execute =  fn() ->
              signals = json_command["signals"]
              channels_with_values = Enum.map(signals, fn({signal, value}) ->
                case value do
                  "arbitration" ->
                    {signal, :arbitration}
                  _ ->
                    {signal, value}
                end
              end)
              # Logger.debug "write received: from: #{inspect self()} data: #{inspect channels_with_values}"
              add_namespace_and_execute(:publish, [state.signal_server_proxy, channels_with_values, state.socket], json_command["namespace"])
            end
            validate_request(json_command, state.write_schema, execute, state.socket)
            :ok
          "read" ->
            execute = fn() ->
              signals = json_command["signals"]
              channels_with_values = add_namespace_and_execute(:read_values, [state.signal_server_proxy, signals], json_command["namespace"])
              Logger.debug "read received: from: #{inspect self()} signals: #{inspect signals} result #{inspect channels_with_values}"
              json_values = Poison.encode!(Enum.into(channels_with_values, %{}))

              return = package_response json_command, %{result_read: Enum.into(channels_with_values, %{})}
              write_line(state.socket, {:ok, Poison.encode!(return)})
            end
            validate_request(json_command, state.read_sub_unsub_schema, execute, state.socket)
            :ok
          _ ->
            :error
        end
      _ ->
        # TODO this answer should be webbified somewhere?!?
        write_line(state.socket, {:ok, Poison.encode!(%{"error" => "bad json: #{message}"})})
    end
  end

  def handle_info(message , socket) do
    Logger.debug "waste enpoint....: #{inspect self()} socket: #{inspect socket} message: #{inspect message}"
    {:noreply, socket}
  end

  def handle_cast({:signal, msg}, state) do
    # Logger.debug "received signal about to send to socket: #{inspect state} channels: #{inspect msg.name_values}"

    json_values = Poison.encode!(Enum.into(msg.name_values, %{}))
    json_respose_payload = %{signals: Enum.into(msg.name_values, %{}), timestamp: msg.time_stamp}

    write_line(state.socket, {:ok, Poison.encode!(json_respose_payload)})
    {:noreply, state}
  end

  defp add_namespace_and_execute(function, args, namespace) do
    case namespace do
      nil -> apply(SignalServerProxy, function, args)
      namespace -> apply(SignalServerProxy, function, args ++ [String.to_atom(namespace)])
    end
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text <> "\n")
  end
end
