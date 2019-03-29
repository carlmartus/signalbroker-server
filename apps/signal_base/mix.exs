defmodule SignalBase.Mixfile do
  use Mix.Project

  def project do
    [
      app: :signal_base,
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
  end

  def application, do: [
    extra_applications: [:logger],
    mod: {SignalBase.Application, []},
  ]

  defp deps, do: [
    {:app_counter, in_umbrella: true},
    {:app_debug, in_umbrella: true},
    # FIXME: Circular dependencies between can and signal_base!
    # {:payload, in_umbrella: true},
    {:util, in_umbrella: true},
  ]
end
