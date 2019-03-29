defmodule Lin.Ldf do

  require Logger
  @moduledoc """
  # LIN .ldf file parser.

  ## Output

  A map containing all fields from a `.ldf` file.
  Top lever fields are:
   * `global`
   * `section`
  """

  # Structure representing data in .ldf-file
  defstruct [
    master: [],
    slaves: [],
    signals: [],
    frames: [],
    scheduling: [],
    signal_encoding_type: [],
    signal_representation: [],
    diagnostic_signals: [],
    diagnostic_frames: []
  ]

  # Structures representing .ldf fields
  defmodule Signal do
    defstruct [
      name: "",
      size: 0, # Can be bit(0..7), byte(8), integer(16), Arraye(16..64)
      initial_value: 0,
      publisher: "",
      subscribers: [],
    ]
  end

  defmodule DiagnosticSignal do
    defstruct [
      name: "",
      size: 0, # Can be bit(0..7), byte(8), integer(16), Arraye(16..64)
      initial_value: 0,
    ]
  end

  defmodule Frame do
    defstruct [
      name: "",
      id: nil,
      publisher: "",
      frame_size: 0,
      signals: [],
    ]
  end

  defmodule DiagnosticFrame do
    defstruct [
      name: "",
      id: nil,
      signals: [],
    ]
  end

defmodule FrameSignals do
    defstruct [
      signal_name: [],
      signal_offset: [],
    ]
  end


  defmodule SchedulingTable do
    defstruct [
      table_name: "",
      frame_schedules: [],
    ]
  end

  defmodule SignalEncodingType do
    defstruct [
      signal_name: "",
      encodings: [],
    ]
  end

  defmodule SignalEncoding do
    defstruct [
      physical: [],
      logical: [],
    ]
  end


  defmodule Logical do
    defstruct [
      name: [],
      value: [],
    ]
  end

  defmodule Physical do
    defstruct [
      min: [],
      max: [],
      scale: [],
      offset: [],
      text: [],
    ]
  end

  defmodule SignalRepresentation do
    defstruct [
      encoding_type_name: "",
      signals: [],
    ]
  end


  @regex_nodes ~r/\s*(\w+)\:\s+([A-Z,\s]*)/
  @regex_section_recursives ~r/\s*(\w+|.*)\s*\{((?>[^{}]|(?R))*)\}/
  @regex_signal_line ~r/\s*(\w+)\:\s+(\d+)\,\s+(-?\d+)\,\s*((?:\w+,?\s*)*);/
  @regex_frame ~r/\s*(\w+)\:\s+(\w+)\,\s+(\w+)\,\s+(\d+)\s+\{\s*((?:\w+\,\s*\d*;\s*)*)\}/
  @regex_scheduling ~r/\s*(\w+)\s+\{\s*((?:\w+\s+\w+\s+(?:\d+\.\d+)\s+\w+;\s*)*)\}/
  @regex_signal_encoding ~r/\s*(\w+)\s+\{\s*((?:.*;\s*)*)\}/
  @regex_signal_representations ~r/\s*(\w+)\s*\:\s*((?:.|\n)+);/
  @regex_diagnostic_signals ~r/\s*(\w+)\:\s+(\d+)\,\s+(\d+);/
  @regex_diagnostic_frame ~r/\s*(\w+)\:\s+(\d+)\s+\{\s*((?:\w+\,\s*\d*;\s*)*)\}/

  def parse_file(path) do
    path
    |> File.read!()
    |> parse_data()
  end

  def parse_data(data) do
    Regex.scan(@regex_section_recursives, data)
    |> Enum.reduce(%Lin.Ldf{}, fn(match, acc) ->
      [_, section_name, section_content] = match
      case section_name do
        "Nodes" ->
          Regex.scan(@regex_nodes, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
            [_, master_or_slave, nodes] = match
            case master_or_slave do
              "Master" ->
                %Lin.Ldf{acc| master: Enum.map(String.split(nodes), fn(entry) -> String.trim(String.trim(entry), ",") end)}
              "Slaves" ->
                %Lin.Ldf{acc| slaves: Enum.map(String.split(nodes), fn(entry) -> String.trim(String.trim(entry), ",") end)}
            end
          end)


        "Signals" ->
          Regex.scan(@regex_signal_line, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
            [_, signal_name, size, initial_value, pubsubs] = match

            [publisher | subscribers] =
              pubsubs
              |> String.split(",", trim: true)
              |> Enum.map(&String.trim/1)

            add = %Signal{
              name: signal_name,
              size: elem(Integer.parse(size), 0),
              initial_value: elem(Integer.parse(initial_value), 0),
              publisher: publisher,
              subscribers: subscribers,
            }

            %Lin.Ldf{acc| signals: [add | acc.signals]}
          end)

        "Diagnostic_signals" ->
          Regex.scan(@regex_diagnostic_signals, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
            [_, signal_name, size, initial_value] = match
            add = %Signal{
              name: signal_name,
              size: elem(Integer.parse(size), 0),
              initial_value: elem(Integer.parse(initial_value), 0),
              publisher: nil,
              subscribers: nil
            }

            %Lin.Ldf{acc| signals: [add | acc.signals]}
          end)

        "Frames" ->
          Regex.scan(@regex_frame, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
             [_, frame_name, frame_id, publisher, frame_size, frame_signals] = match

             [_ | tail] = frame_signals
             |> String.split(";", trim: true)
             |> Enum.map(&String.trim/1)
             |> Enum.reverse()

             signals = Enum.reverse(tail)
             |> Enum.map(fn(x) ->
                String.split(x, ",", trim: true)
                |> Enum.map(&String.trim/1)
                end) |> Enum.reduce(%FrameSignals{}, fn(signals, acc) ->
                          %FrameSignals{signal_name: [Enum.at(signals, 0) | acc.signal_name], signal_offset: [elem(Integer.parse(Enum.at(signals, 1)), 0) | acc.signal_offset]}
                        end)

            {frame_dec, _crap} = Integer.parse(String.slice(frame_id, 2..-1), 16)
             add = %Frame{
              name: frame_name,
              id: frame_dec,
              publisher: publisher,
              frame_size: elem(Integer.parse(frame_size), 0),
              signals: signals,
             }
            #IO.inspect add
             %Lin.Ldf{acc | frames: [add | acc.frames]}
           end)

        "Diagnostic_frames" ->
          Regex.scan(@regex_diagnostic_frame, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
             [_, frame_name, frame_id, frame_signals] = match

             [_ | tail] = frame_signals
             |> String.split(";", trim: true)
             |> Enum.map(&String.trim/1)
             |> Enum.reverse()

             signals = Enum.reverse(tail)
             |> Enum.map(fn(x) ->
                String.split(x, ",", trim: true)
                |> Enum.map(&String.trim/1)
                end) |> Enum.reduce(%FrameSignals{}, fn(signals, acc) ->
                          %FrameSignals{signal_name: [Enum.at(signals, 0) | acc.signal_name], signal_offset: [elem(Integer.parse(Enum.at(signals, 1)), 0) | acc.signal_offset]}
                        end)

            {frame_dec, _crap} = Integer.parse(frame_id)
             add = %Frame{
              name: frame_name,
              id: frame_dec,
              publisher: "CCM",
              frame_size: 8,
              signals: signals,
             }
            #IO.inspect add
             %Lin.Ldf{acc | frames: [add | acc.frames]}
           end)

        "Schedule_tables" ->
          Regex.scan(@regex_scheduling, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
             [_, schedule_table_name, frame_schedule] = match

             [_ | tail] = frame_schedule
             |> String.split(";", trim: true)
             |> Enum.map(&String.trim/1)
             |> Enum.reverse()
             #IO.inspect tail
             # TODO: fix this, doesn't need to be list
             schedules = Enum.reverse(tail)
            |> Enum.map(fn(x) ->
                String.split(x, " ", trim: true)
                |> Enum.map(&String.trim/1)
                end) |> Enum.map(fn(schedules) ->
                 %{frame_name: Enum.at(schedules, 0), frame_delay: Enum.at(schedules, 2)}
             end)

             add = %SchedulingTable{
              table_name: schedule_table_name,
              frame_schedules: schedules,
             }
             %Lin.Ldf{acc | scheduling: [add | acc.scheduling]}
           end)

        "Signal_encoding_types" ->
          Regex.scan(@regex_signal_encoding, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
             [_, signal_name, signal_values] = match

             [_ | tail] = signal_values
             |> String.split(";", trim: true)
             |> Enum.map(&String.trim/1)
             |> Enum.reverse()
             #IO.inspect tail

            encodings = Enum.reverse(tail)
            |> Enum.map(fn(x) ->
                String.split(x, ",", trim: true)
                |> Enum.map(&String.trim/1)
                end) |> Enum.reduce(%SignalEncoding{}, fn(encodings, acc) ->
                        #IO.inspect encodings
                          if (Enum.at(encodings, 0) == "logical_value") do
                            add = %Logical{
                              name: Enum.at(encodings, 2),
                              value: elem(Integer.parse(Enum.at(encodings, 1)), 0),}
                            %SignalEncoding{logical: [add | acc.logical]}
                          else
                              add = %Physical{
                              min: elem(Float.parse(Enum.at(encodings, 1)), 0),
                              max: elem(Float.parse(Enum.at(encodings, 2)), 0),
                              scale: elem(Float.parse(Enum.at(encodings, 3)), 0),
                              offset: elem(Float.parse(Enum.at(encodings, 4)), 0),
                              text: Enum.at(encodings, 5),
                              }
                            %SignalEncoding{physical: [add | acc.physical]}
                          end
                        end)

             add = %SignalEncodingType{
              signal_name: signal_name,
              encodings: encodings,
             }
             #IO.inspect add
             %Lin.Ldf{acc | signal_encoding_type: [add | acc.signal_encoding_type]}
           end)

        "Signal_representation" ->
          Regex.scan(@regex_signal_representations, section_content)
          |> Enum.reduce(acc, fn(match, acc) ->
             [_, encoding_type_name, signals_] = match

              signals = signals_
              |> String.split(",", trim: true)
              |> Enum.map(&String.trim/1)

             add = %SignalRepresentation{
              encoding_type_name: encoding_type_name,
              signals: signals,
             }
             #IO.inspect add
             %Lin.Ldf{acc | signal_representation: [add | acc.signal_representation]}
           end)

        _ ->
          #IO.warn("Unknown section: #{inspect section_name}")
          :ok
          acc
      end
    end)
  end

  def get_signal_id(ldf_frames, name) do
    [signal] =
    Enum.map(ldf_frames, fn(frame) ->
      Enum.map(frame.signals.signal_name, fn(signal_name) ->
        case signal_name do
          ^name -> frame.id
          _ -> :no_match
        end
      end)
    end)
    |> Enum.flat_map(fn (x) -> x end)
    |> Enum.filter(fn(entry) -> entry != :no_match end)

    # Logger.debug "match #{inspect signal}"
    signal
  end

  def get_signal_start_bit(ldf_frames, name) do
    [signal] =
    Enum.map(ldf_frames, fn(frame) ->
      # Logger.debug ("stuff #{inspect frame.signals.signal_name}")
      zipped = Enum.zip(frame.signals.signal_name, frame.signals.signal_offset)
      Enum.map(zipped, fn({signal_name, signal_offset}) ->
        case signal_name do
          ^name -> signal_offset
          _ -> :no_match
        end
      end)
    end)
    |> Enum.flat_map(fn (x) -> x end)
    |> Enum.filter(fn(entry) -> entry != :no_match end)

    # Logger.debug "startbit is: #{inspect signal}"
    signal
  end

  def get_signal_size(signals, name) do
    [size] =
      Enum.map(signals, fn(signal) ->
        case signal.name == name do
          true -> signal.size
          false -> :no_match
        end
      end)
      |> Enum.filter(fn(entry) -> entry != :no_match end)
    # Logger.debug "size is #{inspect size}"
    size
  end


  def get_signal_scale(ldf_data, name, key, default) do
    value =
      try do
        [encoding_type_name] =
          Enum.map(ldf_data.signal_representation, fn(signal_repr) ->
            case Enum.member?(signal_repr.signals, name) do
              true -> signal_repr.encoding_type_name
              false -> :no_match
            end
          end)
          |> Enum.filter(fn(name) -> name != :no_match end)
        # Logger.debug ("encoding type is: #{inspect encoding_type_name}")

        [signal_encoding] =
        Enum.map(ldf_data.signal_encoding_type, fn(encoding) ->
          case encoding.signal_name == encoding_type_name do
            true -> encoding.encodings
            false -> :no_match
          end
        end)
        |> Enum.filter(fn(encodings) -> encodings != :no_match end)

        # Logger.debug ("signal_encoding is: #{inspect signal_encoding}")
        value =
          case signal_encoding.physical do
            [physical] -> Map.get(physical, key)
            [] -> default
          end
      rescue
        _ ->
          Logger.warn ("bad ldf file. Cannot find #{inspect key} for signal #{inspect name} returning default value which is #{inspect default}")
          default
      end
    # Logger.debug ("value_is: #{inspect value}")
    value
  end

    # Find length of the from that an specific signal belongs to.
  def get_frame_of_signal_length(ldf_frames, name) do
    [signal] =
    Enum.map(ldf_frames, fn(frame) ->
      Enum.map(frame.signals.signal_name, fn(signal_name) ->
        case signal_name do
          ^name -> frame.frame_size
          _ -> :no_match
        end
      end)
    end)
    |> Enum.flat_map(fn (x) -> x end)
    |> Enum.filter(fn(entry) -> entry != :no_match end)

    # Logger.debug "match #{inspect signal}"
    signal
  end


  def write_arb_helper do
    write_arbitration_frame(Payload.Name.generate_name_from_namespace("Lin", :server),
      Payload.Name.generate_name_from_namespace("Lin", :desc),
      "CCMLIN18Fr03")
  end

  def write_arbitration_frame(lin_server, lin_desc, frame) do
    GenServer.cast(lin_server, {:write_arbitration_frame, frame.id, div(frame.length, 8)})
  end

end
