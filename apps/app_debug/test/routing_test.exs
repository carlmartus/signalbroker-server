defmodule RoutingTest do
  use ExUnit.Case
  alias Debug.Route.Ets, as: R

  @bignum 0_500_000

  test "Create router" do
    {:ok, _} = R.start_link(:r)
    assert GenServer.stop(:r) == :ok
  end

  test "Register and publish" do
    {:ok, _} = R.start_link(:r)
    R.reg(:r, :a, self())
    R.pub(:r, :a, :value)

    assert_receive {:"$gen_cast", {:signal, :a, :value}}
    assert GenServer.stop(:r) == :ok
  end

  test "Pingpong with #{@bignum} events" do
    {:ok, _} = R.start_link(:r)
    {:ok, pp} = Debug.Route.PingPong.start_link(self(), {:signal, :b, :value_b})

    R.reg(:r, :a, pp)
    R.reg(:r, :b, self())

    for _ <- 1..@bignum do
      R.pub(:r, :a, :value_a)
      assert_receive {:"$gen_cast", {:signal, :b, :value_b}}
    end

    assert GenServer.stop(:r) == :ok
    assert GenServer.stop(pp) == :ok
  end
end
