defmodule MarkdownTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :markdown_test,
      version: "0.1.0",
      elixir: "~> 1.10-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.9.0", only: :dev, runtime: false},
    ]
  end
end
