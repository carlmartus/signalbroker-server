defmodule SignalServer.Mixfile do
  use Mix.Project

  def project, do: [
    apps_path: "apps",
    version: app_version(),
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    build_path: "_build",
    deps: deps(),
    aliases: aliases(),
    test_coverage: [tool: ExCoveralls],
  ]

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [
      {:excoveralls, "~> 0.8", only: :test},
      {:credo, "0.8.10", only: [:dev, :test]},
      {:distillery, "~> 2.0.12", runtime: false},
    ]
  end

  defp aliases, do: [
  # TODO: Strange! If we run the tests with --cover the signal_base_test.exs:115 test fails
  #  test: "test --no-start --cover",
    test: "test --no-start"
  ]

  defp app_version do
      with {out, 0} <- System.cmd("git", ~w[describe], stderr_to_stdout: true) do
        out
        |> String.trim()
        |> String.split("-")
        |> Enum.take(2)
        |> Enum.join(".")
        |> String.trim_leading("v")
      else
        _ -> "0.1.0"
      end
  end
end
