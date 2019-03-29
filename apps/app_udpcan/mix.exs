defmodule AppUdpcan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :app_udpcan,
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

  def application, do: [
    extra_applications: [:logger],
    mod: {CanUdp.Application, []}
  ]

  defp deps, do: [
    {:poison, "~> 3.0"},
    {:payload, in_umbrella: true},
    {:signal_base, in_umbrella: true},
    {:util, in_umbrella: true},
  ]
end
