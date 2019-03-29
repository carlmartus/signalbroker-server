defmodule Special do
  require Logger

  @doc """
  Install reflector that listens to
  """
  def install_reflector_a() do
  end

  def echo_a() do
    SignalServerProxy.publish(:gateway_pid, [{"A", 10}, {"B", 11}, {"C", 12}], :b)
  end

  def reg_a() do
    SignalServerProxy.register_listeners(:gateway_pid, ["A"], :a, self())
  end

  def echo_process() do
    spawn(Special, :echo_run, [])
  end

  def echo_run() do
    receive do
      any -> IO.puts "ECHO GOT: #{inspect any}"
    end
    echo_run()
  end

  # write to other channel
  def loopback_frames_write(from, target) do
    signals = SignalBase.get_channels_by_tag(from, :frame)

    Enum.map(signals, fn(name) ->
      SignalBase.register_listeners(from, [name], :null, target)
    end)

    :ok
  end

  def loopback_omnius(from, target) do
    SignalBase.register_omnius_listener(from, :nene, target)
  end

  # super expensive
  def loopback_naive_all(from, target) do
    SignalBase.get_channels(from)
    |> Enum.map(fn(name) ->
      SignalBase.register_listeners(from, [name], :meme, target)
    end)
  end

  # ExProf
  # ======
  def exprof_many() do
    Debug.exprof_big [
      :vcan0_sb,
      :vcan0_desc,
      :vcan0_signal,
      :vcan0_conn,
      :vcan0_canwriter,
      Counter.Timer,
      Counter,
      :gateway_pid,
      :vcan0_signal_read_cache,
    ]
  end

  # BenchA
  # ======

  @doc """
  Benchmark internally in Elixir.
  ```
  iex> Special.bencha_run(100_000) |> Special.write_csv("/tmp/bencha.csv")
  ```
  """
  def bencha_run(count) do
    Special.BenchA.start_link({self(), count})
    receive do x -> x end
  end

  # BenchB
  # ======

  @doc """
  Benchmark ping times with Unix domain socket interface.
  ```
  iex> Special.benchb_install()
  ```

  From a terminal:
  ```
  ./benchb > /tmp/benchb.csv
  ```

  Then in IEx:
  ```
  iex> Special.benchb_echo()
  ```

  If this doesn't work. Then restart IEx.
  """
  def benchb_install() do
    SignalServerProxy.register_listeners(:gateway_pid, ["BenchB"], :a, :unixds_client_1)
  end

  def benchb_self() do
    SignalServerProxy.register_listeners(:gateway_pid, ["BenchB"], :b, self())
  end

  def benchb_echo() do
    SignalServerProxy.publish(:gateway_pid, [{"BenchB", -1}], :c)
  end

  # BenchC
  # ======

  @doc """
  Have this in the project `config.exs`:
  ```
  %{physical: %{type: "can", human_file: "apps/app_ngcan/config/benchc.json", device_name: "vcan4", signal_base_pid: :signal_base_benchc, id: :phys4},
  router: %{signal_base_pid: :signal_base_benchc, namespace: "vcan4"}},
  ],
  ```

  Install with:
  ```
  iex> Special.benchc_install
  ```

  Run CAN benchmark program:
  ```
  ./benchc vcan4 > /tmp/benchc.csv
  ```
  """
  def benchc_install() do
    {:ok, _} = BenchC.start_link()
  end

  # CSV Export
  # ==========

  def histogram_can_signals() do
    1..64
    |> Enum.map(fn(size) ->
      Payload.Descriptions.get_all_names(:vcan0_desc)
      |> Enum.count(fn(signalname) ->
        Payload.Descriptions.get_field_by_name(:vcan0_desc, signalname).length == size end)
    end)
  end


  def histogram(data) do
    {min, max} = Enum.min_max(data)
    min..max
    |> Enum.map(fn n ->
      Enum.count(data, fn x -> x == n end)
    end)
  end

  def write_csv(result, path) do
    csv = result
    |> Enum.map(fn m -> "#{m}\n" end)
    |> Enum.join()

    File.write(path, csv)
  end
end

defmodule Special.BenchA do
  use GenServer
  require Logger
  alias SignalBase.Message

  defmodule State, do: defstruct [
    parent: nil,
    mode: :recieve,
    count: 10,
    time_stamp: nil,
    measurement: []
  ]

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init({parent, count}) do
    SignalServerProxy.register_listeners(:gateway_pid, ["BenchA"], :a, self())
    state = send_ping(%State{parent: parent, count: count})
    {:ok, state}
  end

  def handle_cast(
    {:signal, %Message{name_values: [{"BenchA", :message}]}}, state) do

    # Stamp
    end_stamp = time_stamp()
    count = state.count - 1

    measured_time = end_stamp - state.time_stamp
    #Logger.info "Time measured: #{measured_time}"

    state = %State{state| measurement: [measured_time | state.measurement]}

    if count > 0 do
      new_state = send_ping(%State{state| count: count})
      #Logger.info "Benchmark ponged"
      {:noreply, new_state}
    else
      Logger.info "Benchmark done, closing!"
      send(state.parent, state.measurement)
      {:stop, :normal, :idle}
    end
  end

  defp send_ping(state) do
    stamp = time_stamp()
    SignalServerProxy.publish(:gateway_pid, [{"BenchA", :message}], :b)
    %State{state | time_stamp: stamp}
  end

  defp time_stamp() do
    System.monotonic_time(:microseconds)
  end
end

defmodule BenchC do
  use GenServer
  alias SignalBase.Message

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    sub("BenchC_a")
    for n <- 1..8 do
      sub("BenchC_c_#{n}")
    end
    {:ok, nil}
  end

  defp sub(channel) do
    IO.puts "Sub to #{channel}"
    SignalServerProxy.register_listeners(:gateway_pid, [channel], :bla, __MODULE__, :vcan4)
  end

  #def handle_cast({:signal, [{"BenchC_a", _}], _from, _timestamp}, state) do
  def handle_cast({:signal, %Message{name_values: [{"BenchC_a", _}]}}, state) do
  #def handle_cast({:signal, _}, state) do
    #IO.puts "Signal simple!"

    SignalServerProxy.publish(:gateway_pid, [{"BenchC_b", 20}], :bla, :vcan4)
    {:noreply, state}
  end

  def handle_cast({:signal, %Message{name_values: signals_with_names}}, state)
  when length(signals_with_names) == 8 do
    #IO.puts "Signal many!"

    SignalServerProxy.publish(:gateway_pid, [
      {"BenchC_d_1", 1},
      {"BenchC_d_2", 2},
      {"BenchC_d_3", 3},
      {"BenchC_d_4", 4},
      {"BenchC_d_5", 5},
      {"BenchC_d_6", 6},
      {"BenchC_d_7", 7},
      {"BenchC_d_8", 8},
    ], :bla, :vcan4)
    {:noreply, state}
  end
end
