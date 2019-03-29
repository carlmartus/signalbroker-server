defmodule Payload.Interface do
  def write(pid, can_id, payload) do
    GenServer.cast(pid, {:write, can_id, payload})
  end
end
