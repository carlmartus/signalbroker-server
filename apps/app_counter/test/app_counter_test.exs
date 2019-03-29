defmodule AppCounterTest do
  use ExUnit.Case

  test "No ticks" do
    {:ok, c} = Counter.start_link(:ok)
    {:ok, t} = Counter.Timer.start_link(:ok)

    assert GenServer.stop(c, :normal) == :ok
    assert GenServer.stop(t, :normal) == :ok
  end

  test "One some" do
    {:ok, c} = Counter.start_link(:ok)
    {:ok, t} = Counter.Timer.start_link(:ok)

    Counter.add_listen(self())

    Counter.tick_signal()
    Counter.tick_frame(2)

    Counter.Timer.force_tick()

    assert_receive {
      :"$gen_cast",
      {:counter_stats, %Counter.Stats{signals: 1, frames: 2}}
    }

    assert GenServer.stop(c, :normal) == :ok
    assert GenServer.stop(t, :normal) == :ok
  end
end
