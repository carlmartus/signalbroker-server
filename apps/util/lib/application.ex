defmodule Util.Application do
  use Application
  require Logger

  def start(_type, _args) do
    config_path = if !Util.Config.is_test do
      "#{System.cwd()}/configuration/interfaces.json"
    else
      "#{System.cwd()}/../../configuration/interfaces.json"
    end

    Logger.info "Loading main configuration file #{config_path}"

    Supervisor.start_link([
      {Util.Config, config_path},
    ], strategy: :one_for_one)
  end
end
