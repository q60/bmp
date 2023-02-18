defmodule BMP.MixProject do
  use Mix.Project

  def project do
    [
      app: :bmp,
      version: "0.1.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir library allowing to interact with bitmap images.",
      package: hex()
    ] ++ docs()
  end

  def docs do
    [
      name: "BMP",
      source_url: "https://github.com/q60/bmp",
      docs: [
        main: "BMP",
        logo: "assets/logo.png",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def hex do
    [
      name: "bmp",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/q60/bmp"
      }
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
      {:ex_doc, "~> 0.29.1", only: :dev, runtime: false}
    ]
  end
end
