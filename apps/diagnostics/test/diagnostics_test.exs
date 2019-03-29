defmodule DiagnosticsTest do
  use ExUnit.Case
  doctest Diagnostics

  test "convert micros to hex" do
    assert Diagnostics.get_code_for_delay(200) == 0xF2
  end

  test "convert micros to hex test 0" do
    assert Diagnostics.get_code_for_delay(0) == 0xF1
  end

  test "convert micros to hex test saturate" do
    assert Diagnostics.get_code_for_delay(1000) == 0xF9
  end
end
