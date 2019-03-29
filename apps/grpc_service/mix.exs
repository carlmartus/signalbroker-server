defmodule GRPCService.Mixfile do
  use Mix.Project

  def project do
    [
      app: :grpc_service,
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
      applications: [:grpc],
      extra_applications: [:logger],
      mod: {GRPCService.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:util, in_umbrella: true},
      {:signal_base, in_umbrella: true},
      {:payload, in_umbrella: true},
      {:grpc, github: "tony612/grpc-elixir"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
