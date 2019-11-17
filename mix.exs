defmodule MarkdownTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :markdown_test,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.9.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12.0", only: [:dev, :test], runtime: false}
    ]
  end
end
