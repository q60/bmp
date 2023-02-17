defmodule BMP.MixProject do
  use Mix.Project

  def project do
    [
      app: :bmp,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ] ++ docs()
  end

  def docs do
    [
      name: "BMP",
      source_url: "https://github.com/q60/bmp",
      docs: [
        main: "BMP",
        extras: ["README.md", "LICENSE"]
      ]
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
