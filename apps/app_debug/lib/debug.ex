defmodule Debug do
  @doc "Run ExProf profiling on pid, lasts 2 seconds"
  def exprof(pid) do
    ExProf.start(pid)
    :timer.sleep 2000
    ExProf.stop()
    ExProf.analyze()
  end


  def exprof_helper() do    
    namespace = "chassis"
    namespace2 = "body"
    Debug.exprof_big [
      :signal_base_pid, Payload.Name.generate_name_from_namespace(namespace, :desc), Payload.Name.generate_name_from_namespace(namespace, :signal), Payload.Name.generate_name_from_namespace(namespace, :server), Payload.Name.generate_name_from_namespace(namespace, :writer), :vcan0_signal_read_cache,
      :signal_base_pid_2, Payload.Name.generate_name_from_namespace(namespace2, :desc), Payload.Name.generate_name_from_namespace(namespace2, :signal), Payload.Name.generate_name_from_namespace(namespace2, :server), Payload.Name.generate_name_from_namespace(namespace2, :writer), :vcan1_signal_read_cache,
    Counter.Timer, Counter, :gateway_pid, :vcan0_signal_read_cache]
  end

  def exprof_big(processes) do
    profs = Enum.map(processes, fn(pid) ->
      {pid, exprof(pid)}
    end)

    total_time =
      Enum.reduce(profs, 0, fn({_, prof}, prof_acc) ->
        prof_acc + Enum.reduce(prof, 0, fn(row, row_acc) ->
          row_acc + row.time
        end)
      end)

    table =
      Enum.map(profs, fn({pid, prof}) ->
        time = Enum.reduce(prof, 0, fn(prof, acc) ->
          acc + prof.time
        end)

        share = time / total_time
        %{"Pid"=>pid, "Time"=>time, "Share"=>share}
      end)

    table
    |> Enum.sort(fn(a, b) ->
      Map.get(a, "Time") >= Map.get(b, "Time")
    end)
    |> Scribe.print()
  end
end
