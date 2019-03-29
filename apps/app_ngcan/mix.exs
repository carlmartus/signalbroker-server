defmodule AppNgCan.Mixfile do
  use Mix.Project

  def project, do: [
    app: :app_ngcan,
    version: "0.1.0",
    build_path: "../../_build",
    config_path: "../../config/config.exs",
    deps_path: "../../deps",
    lockfile: "../../mix.lock",
    elixir: "~> 1.4",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps()
  ]

  def application, do: [
    extra_applications: [:logger, :poison],
    mod: {AppNgCan.Application, []}
  ]

  defp deps, do: [
    {:ng_can, git: "https://github.com/AleksandarFilipov/ng_can"},
    {:poison, "~> 3.0"},
    {:util, in_umbrella: true},
    {:signal_base, in_umbrella: true},
    {:app_counter, in_umbrella: true},
    {:payload, in_umbrella: true},
  ]
end
