defmodule AppLin.Mixfile do
  use Mix.Project

  def project do
    [
      app: :app_lin,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AppLin.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps, do: [
    {:payload, in_umbrella: true},
    {:signal_base, in_umbrella: true},
    {:util, in_umbrella: true},
    {:exprof, "~> 0.2.0"},
    {:scribe, "~> 0.5.0"},
  ]
end
