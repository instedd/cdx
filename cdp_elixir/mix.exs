defmodule CdpElixir.Mixfile do
  use Mix.Project

  def project do
    [ app: :cdp_elixir,
      version: "0.0.1",
      build_per_environment: true,
      dynamos: [CdpElixir.Dynamo],
      compilers: [:elixir, :dynamo, :app],
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:cowboy, :dynamo, :postgrex, :ecto],
      mod: { CdpElixir, [] } ]
  end

  defp deps do
    [
      { :cowboy, github: "extend/cowboy" },
      { :dynamo, "~> 0.1.0-dev", github: "elixir-lang/dynamo" },
      { :postgrex, github: "ericmj/postgrex" },
      { :ecto, github: "elixir-lang/ecto" },
    ]
  end
end
