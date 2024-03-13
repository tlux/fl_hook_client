defmodule FLHook.MixProject do
  use Mix.Project

  @version "2.1.2"
  @github_url "https://github.com/tlux/fl_hook_client"

  def project do
    [
      app: :fl_hook_client,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.post": :test,
        coveralls: :test,
        credo: :test,
        dialyzer: :test,
        test: :test
      ],
      dialyzer: dialyzer(),

      # Docs
      name: "FLHook Client",
      docs: docs()
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
      # needed for excoveralls
      {:castore, "~> 1.0", only: :test},
      {:connection, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.31", only: :dev},
      {:liveness, "~> 1.0", only: :test},
      {:mix_audit, "~> 2.1", only: [:dev, :test]},
      {:mox, "~> 1.1", only: :test}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/fl_hook_client.plt"}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Readme"]
      ],
      main: "readme",
      source_url: @github_url,
      source_ref: "v#{@version}",
      groups_for_modules: [
        Client: [
          FLHook.Config,
          FLHook.Client
        ],
        Commands: [
          FLHook.Command
        ],
        Results: [
          FLHook.Dict,
          FLHook.Duration,
          FLHook.Event,
          FLHook.FieldType,
          FLHook.Result
        ],
        "Encoding & Decoding": [
          FLHook.Codec,
          FLHook.XMLText
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      description: description(),
      exclude_patterns: [~r/\Aexamples/, ~r/\Apriv\/plts/],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end
end
