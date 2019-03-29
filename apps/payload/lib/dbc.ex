defmodule DBC do
  require Logger

  defmodule PackInfo, do: defstruct [
      name: "",
      startbit: 0,
      length: 0,
      is_signed: false,
      factor: 1,
      offset: 0,
      margin_lo: 0,
      margin_hi: 0,
      unit: "",
      tags: [],
      is_raw: false
    ]

  defmodule FrameInfo, do: defstruct [
    can_id: 0,
    name: "",
    size_bytes: 8,
    tag: "",
  ]

  defmodule FrameOption, do: defstruct [
    can_id: 0,
    option_name: "",
    #send_type: :fixed_period, # :fixed_period, :event, :enabled_periodic
    value: 0,
  ]

  defmodule SignalOption, do: defstruct [
    can_id: 0,
    option_name: "",
    signal_name: "",
    value: 0,
    #send_type: :cyclic, # :cyclic, :on_write, :on_write_repeate, :on_change, :on_change_repeate, :if_active, :if_active_repeate, :none
    #"Cyclic","OnWrite","OnWriteWithRepetition","OnChange","OnChangeWithRepetition","IfActive","IfActiveWithRepetition","NoSigSendType";
  ]

  defmodule StreamAcc, do: defstruct [
    frame_info: nil,
  ]

  # CLIENT

  @regex_sg_pre ~r/^\s*SG_\s+/
  @regex_sg ~r/\s*SG_\s+(\w+)\s*:\s*(\d+)\|(\d+)\@(\d+)([\+\-])\s+\((-?\d*\.?\d+)\s*,\s*(-?\d*\.?\d+)\)\s*\[(-?\d*\.?\d+)\|(-?\d*\.?\d+)\]\s*"(.*)"\s*(.*)/
  @regex_bo_pre ~r/^BO_\s+/
  @regex_bo ~r/^BO_\s+(\d+)\s+(\w+)\s*:\s*(\d+)\s*(\w+)/
  @regex_babo_pre ~r/^BA_\s+\"\w+\"\s+BO_/
  @regex_babo ~r/^BA_\s+\"(\w+)\"\s+BO_\s+(\d+)\s+(\d+(?:\.\d+)?)\s*;$/
    #@regex_basg_pre ~r/^BA_\s+\"\w+\"\s+SG_/
  @regex_basg ~r/^BA_\s+\"(\w+)\"\s+SG_\s+(\d+)\s+(\w+)\s+(\d+)\s*;$/

  def line(line) do
    cond do
      String.match?(line, @regex_sg_pre) ->
        {:sg, Regex.scan(@regex_sg, line) |> packet_sg}
      String.match?(line, @regex_bo_pre) ->
        {:bo, Regex.scan(@regex_bo, line) |> packet_bo}
      String.match?(line, @regex_babo_pre) ->
        {:babo, Regex.scan(@regex_babo, line) |> packet_babo}
      String.match?(line, @regex_basg) ->
        {:basg, Regex.scan(@regex_basg, line) |> packet_basg}
      true -> :none
    end
  end

  @doc """
  Parse a .dbc file.

  callback should take any of these parameters:
   (:can_frame, frame_info) # SG_
   (:can_field, frame_info, pack_info) # SG_
   (:comment, can_id, name, comment) # CM_
   (:type, can_id, name, comment) # BA_
  """
  def stream(file_path, acc, callback) do
    File.stream!(file_path)
    |> Enum.reduce({%StreamAcc{}, acc}, fn line, {acc_stream, acc_param} = both ->
      case line(line) do
        {_, :none} ->
          Logger.warn "Failed to parse! \"#{line}\""
          both
        {:sg, pack_info} -> {
          acc_stream,
          callback.({:can_field, acc_param, acc_stream.frame_info, pack_info})
        }
        {:bo, frame_info} -> {
          %StreamAcc{acc_stream | frame_info: frame_info},
          callback.({:can_frame, acc_param, frame_info})
        }
        {:babo, frame_schedule} -> {
          acc_stream,
          callback.({:frame_option, acc_param, frame_schedule})
        }
        {:basg, signal_schedule} -> {
          acc_stream,
          callback.({:signal_option, acc_param, signal_schedule})
        }
        :none -> both
      end
    end)
    |> elem(1)
  end

  # INTERNAL

  defp packet_sg([]), do: :none
  defp packet_sg([[_, name, startbit, length, _zero, is_signed, factor, offset,
                   margin_lo, margin_hi, unit, tags]]), do:
    %PackInfo{
      name: name,
      startbit: startbit |> int |> motorola_byte,
      length: int(length),
      is_signed: String.equivalent?("-", is_signed),
      factor: float(factor), offset: float(offset),
      margin_lo: float(margin_lo), margin_hi: float(margin_hi),
      unit: unit,
      tags: String.split(tags, ",", trim: true),
      is_raw: is_one(float(factor)) and is_zero(float(offset))
    }

  # this is likely i diagnostics message, mark it as raw
  defp is_one(1), do: true
  defp is_one(1.0), do: true
  defp is_one(_number), do: false

  defp is_zero(0), do: true
  defp is_zero(0.0), do: true
  defp is_zero(_number), do: false

  defp packet_bo([]), do: :none
  defp packet_bo([[_, can_id, name, size_bytes, tag]]),
    do: %FrameInfo{
      can_id: int(can_id),
      name: name,
      size_bytes: int(size_bytes),
      tag: tag,
    }

  defp packet_babo([]), do: :none
  defp packet_babo([[_, option_name, can_id, value]]) do
    %FrameOption{
      can_id: int(can_id),
      option_name: option_name,
      value: int(value),
    }
  end

  defp packet_basg([]), do: :none
  defp packet_basg([[_, option_name, can_id, signal_name, value]]) do
    %SignalOption{
      option_name: option_name, can_id: int(can_id),
      signal_name: signal_name, value: int(value),
    }
  end

  defp float(txt), do: txt |> Float.parse() |> elem(0)
  defp int(txt), do: txt |> Integer.parse() |> elem(0)

  def motorola_byte(startbit),
    do: (rem(startbit, 8) * -1)+(div(startbit + 8, 8) * 8)-1
end
