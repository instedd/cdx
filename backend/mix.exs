defmodule Cdp.Mixfile do
  use Mix.Project

  def project do
    [ app: :cdp,
      version: "0.0.1",
      build_per_environment: true,
      dynamos: [Cdp.Dynamo],
      compilers: [:elixir, :dynamo, :app],
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:cowboy, :dynamo, :postgrex, :ecto],
      mod: { Cdp, [] } ]
  end

  defp deps do
    [
      { :cowboy, github: "extend/cowboy" },
      { :dynamo, "~> 0.1.0-dev", github: "elixir-lang/dynamo" },
      { :postgrex, github: "ericmj/postgrex" },
      { :ecto, github: "elixir-lang/ecto" },
      { :json, github: "cblage/elixir-json" },
      { :tirexs, github: "roundscope/tirexs" },
      { :amqp_client, github: "jbrisbin/amqp_client" },
    ]
  end
end
