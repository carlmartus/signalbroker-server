defmodule Diagnostics.Mixfile do
  use Mix.Project

  def project, do: [
    app: :diagnostics,
    version: "0.1.0",
    build_path: "../../_build",
    config_path: "../../config/config.exs",
    deps_path: "../../deps",
    lockfile: "../../mix.lock",
    elixir: "~> 1.5",
    start_permanent: Mix.env == :prod,
    deps: deps(),
  ]

  # Run "mix help compile.app" to learn about applications.
  def application, do: [
    extra_applications: [:logger],
    mod: {Diagnostics.Application, []}
  ]

  defp deps, do: [
    {:signal_base, in_umbrella: true},
    {:util, in_umbrella: true},
  ]
end
