defmodule DelayAgent do

  # state currently only holds the name of the database

  # require Logger

  @doc """
  sets the inital state to dbname.
  """
  def start_link(list) do
    Agent.start_link(fn -> list end, name: __MODULE__)
  end

  @doc """
  just returns the intial state.
  """
  def get_state do
    Agent.get(__MODULE__, fn list -> list end)
  end

  @doc """
  ignores the parameter from external state.
  """
  def delay(new_entry) do
    Agent.update(__MODULE__, fn list -> sleep(new_entry, list) end)
  end

  def sleep(new_time, _old_time) do
    #delaytime = (new_time - old_time) * 1000.0
    # Logger.debug "delaytime is #{inspect delaytime}"
    :timer.sleep(10)
    new_time
  end
end
