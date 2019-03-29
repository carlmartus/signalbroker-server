defmodule Lin.Scheduler do
  use GenServer

  defmodule Sched, do: defstruct [
    schedule: nil,
    num_to_send: 0,
    idx: 0,
    len: 0,
  ]

  defmodule State, do: defstruct [
    sched_curr: nil,
    sched_cont: nil,
    desc: nil,
    server_pid: nil,
    num_sent: 0,
    started: false,
    autostart: true,
    signalbase_pid: nil,
    paused: false
  ]

  # CLIENT
  def start_link({name, signalbase_pid, server_pid, desc_pid, conf}) do
    GenServer.start_link(__MODULE__, {signalbase_pid, server_pid, desc_pid, conf}, name: name)
  end

  def num_sent(pid), do: GenServer.call(pid, {:num_sent})

  def run_pattern(pid, ldf_file, table_name, num_repeats \\ 0) do
    if(Util.Config.is_test(), do: Util.Forwarder.send({
      :lin_scheduler_set, table_name, num_repeats
    }))
    GenServer.cast(pid, {:run_pattern, ldf_file, table_name, num_repeats})
  end

  def start_pattern(pid) do
    GenServer.cast(pid, {:start_pattern})
    if(Util.Config.is_test(), do: Util.Forwarder.send(:lin_start))
  end

  def stop_pattern(pid) do
    GenServer.cast(pid, {:stop_pattern})
    if(Util.Config.is_test(), do: Util.Forwarder.send(:lin_stop))
  end

  # SERVER
  defp schedule(timeout) do
    Process.send_after(self(), :schedule, timeout)
  end

  defp load_schedule(ldf_file, schedule_name) do

    # Why would this be here!?
    ldf_file  = if !Util.Config.is_test do
      ldf_file
    else
      "../../" <> ldf_file
    end

    sched_pattern = Enum.at(Enum.filter(Lin.Ldf.parse_file(ldf_file).scheduling, fn(x) -> x.table_name == schedule_name end), 0).frame_schedules |>
    Enum.map(fn(x) -> %{x | frame_delay: elem(Integer.parse(x.frame_delay), 0)} end)
    %Sched{schedule: sched_pattern, len: length(sched_pattern)}
  end

  def init({signalbase_pid, server_pid, desc_pid, conf}) do
    sched = load_schedule(conf.schedule_file, conf.schedule_table_name)

    started = if conf.schedule_autostart and (Enum.count(SignalBase.get_channels_by_tag(signalbase_pid, :frame, self())) != 0) do
      schedule(0)
      true
    else
      false
    end

    {:ok, %State{sched_curr: sched, sched_cont: sched, server_pid: server_pid, started: started, autostart: conf.schedule_autostart,
		 desc: desc_pid, signalbase_pid: signalbase_pid}}
  end

  def handle_info(:schedule, state) do

    current = Enum.at(state.sched_curr.schedule, state.sched_curr.idx)
    if !state.paused do
      SignalBase.publish(state.signalbase_pid, [{current.frame_name, :arbitration}], self())
    end

    sched_curr = if state.sched_curr.num_to_send > 0 do
      if state.sched_curr.num_to_send > 1 do
	%Sched{state.sched_curr | num_to_send: state.sched_curr.num_to_send - 1}
      else
	state.sched_cont
      end
    else
      state.sched_curr
    end

    if state.started and !state.paused do
      schedule(current.frame_delay)
    end

    {:noreply, %State{state | sched_curr: %Sched{sched_curr | idx: rem(state.sched_curr.idx + 1, state.sched_curr.len)},
		      num_sent: state.num_sent + 1}}
  end

  def handle_cast({:signal_server_updated}, state) do
    if !state.started and state.autostart and !state.paused do
      schedule(0)
      {:noreply, %State{state | started: true}}
    else
      {:noreply, state}
    end

  end

  def handle_cast({:run_pattern, ldf_file, table_name, num_repeats}, state) do
    sched = load_schedule(ldf_file, table_name)

    if !state.started do
      schedule(0)
    end

    if num_repeats > 0 do
      {:noreply, %State{state | sched_curr: %Sched{sched | num_to_send: sched.len * num_repeats}, started: true, paused: false}}
    else
      {:noreply, %State{state | sched_curr: sched, sched_cont: sched, started: true, paused: false}}
    end
  end

  def handle_cast({:start_pattern}, state) do
    if state.paused do
      schedule(0)
    end
    {:noreply, %State{state | paused: false}}
  end

  def handle_cast({:stop_pattern}, state) do
    {:noreply, %State{state | paused: true}}
  end

  def handle_call({:num_sent}, _from, state) do
    {:reply, state.num_sent, state}
  end
end
