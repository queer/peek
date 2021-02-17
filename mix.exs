defmodule Peek.MixProject do
  use Mix.Project

  @repo_url "https://github.com/queer/peek"

  def project do
    [
      app: :peek,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Peek at typespecs on your modules and get them in a human-friendly form.",
      package: [
        maintainers: ["amy"],
        links: %{"GitHub" => @repo_url},
        licenses: ["MIT"],
      ],

      # Docs
      name: "peek",
      docs: [
        homepage_url: @repo_url,
        source_url: @repo_url,
        extras: [
          "README.md",
        ],
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.2.1", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
