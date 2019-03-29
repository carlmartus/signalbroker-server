ExUnit.start()

defmodule LinTestHelper do
  use ExUnit.Case

  def list_contains(list, key, value) do
    assert get_field_value(list, key) == value
  end

  def get_field_value(list, key) do
    list
    |> List.keyfind(key, 1)
    |> elem(2)
  end
end
