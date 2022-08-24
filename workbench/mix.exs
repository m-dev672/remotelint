defmodule Workbench.MixProject do
  use Mix.Project

  def project do
    [
      app: :workbench,
      version: "0.1.0",
      elixir: "~> 1.13",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end