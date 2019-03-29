defmodule AppCounter.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Counter, []},
      {Counter.Timer, []},
    ]

    opts = [strategy: :one_for_all, name: AppCounter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
