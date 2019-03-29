defmodule Counter.CSV do
  use GenServer

  def start_link(path), do: GenServer.start_link(__MODULE__, path)

  def init(path), do: {:ok, path}

  def handle_cast({:counter_stats, stats}, path) do
    {:ok, file} = File.open(path, [:append])

    line = [:signals, :frames]
    |> Enum.map(fn field ->
      Map.get(stats, field, 0)
    end)
    |> Enum.join(";")

    IO.write(file, line)
    IO.write(file, "\n")
    File.close(file)

    {:noreply, path}
  end
end
