defmodule FLHook.MixProject do
  use Mix.Project

  @version "1.0.0"
  @github_url "https://github.com/tlux/fl_hook_client"

  def project do
    [
      app: :fl_hook_client,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "FLHook Client",
      source_url: @github_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "A library that allows connecting to Freelancer game servers via an " <>
      "FLHook socket to run commands and receive events."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:connection, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.16", only: :test},
      {:ex_doc, "~> 0.27", only: :dev},
      {:liveness, "~> 1.0", only: :test},
      {:mix_audit, "~> 2.1", only: [:dev, :test]},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/fl_hook_client.plt"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      description: description(),
      exclude_patterns: [~r/\Apriv\/plts/],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end
end
