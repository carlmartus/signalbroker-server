defmodule Util.MixProject do
  use Mix.Project

  def project, do: [
    app: :util,
    version: "0.1.0",
    build_path: "../../_build",
    config_path: "../../config/config.exs",
    deps_path: "../../deps",
    lockfile: "../../mix.lock",
    elixir: "~> 1.6",
    aliases: aliases(),
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]

  def application, do: [
    extra_applications: [:logger],
    mod: {Util.Application, []},
  ]

  defp deps, do: [
    {:poison, "~> 3.0"},
  ]

  defp aliases, do: [
    test: "test --no-start"
  ]
end
