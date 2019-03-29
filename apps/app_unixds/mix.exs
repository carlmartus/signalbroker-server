defmodule UnixDS.Mixfile do
  use Mix.Project

  def project do
    [
      app: :app_unixds,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      elixirc_paths: ["lib"],
      compilers: [:elixir_make] ++ Mix.compilers,
      make_executable: :default,
      make_makefile: "c_lib/elixir.mk",
      make_error_message: :default,
      make_clean: ["clean"],
    ]
  end

  def application, do: [
    extra_applications: [:logger],
    mod: {UnixDS.Application, []},
  ]

  defp deps, do: [
    {:util, in_umbrella: true},
    {:app_lin, in_umbrella: true},
    {:signal_base, in_umbrella: true},
    {:elixir_make, "~> 0.3", runtime: false},
  ]
end
