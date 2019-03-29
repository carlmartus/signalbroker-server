defmodule SignalService.Mixfile do
  use Mix.Project

  def project, do: [
    app: :app_telnet,
    version: "0.1.0",
    build_path: "../../_build",
    config_path: "../../config/config.exs",
    deps_path: "../../deps",
    lockfile: "../../mix.lock",
    elixir: "~> 1.4",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps(),
  ]

  def application, do: [
    extra_applications: [:logger],
    mod: {SignalService.Application, []}
  ]

  defp deps, do: [
    {:signal_base, in_umbrella: true},
    {:poison, "~> 3.1"},
    {:util, in_umbrella: true},
    {:ex_json_schema, "~> 0.5.4"},
  ]
end
