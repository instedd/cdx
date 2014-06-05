defmodule Cdp.Mixfile do
  use Mix.Project

  def project do
    [ app: :cdp,
      version: "0.0.1",
      elixir: "0.13.3",
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
      { :decimal, "~> 0.2.0" },
      { :postgrex, "~> 0.5.0" },
      { :ecto, "~> 0.2.0" },
      { :jsex, github: "talentdeficit/jsex" },
      { :tirexs, github: "manastech/tirexs", branch: "master" },
      { :exrabbit, github: "d0rc/exrabbit" },
      { :timex, github: "bitwalker/timex" },
      { :exlager, github: "khia/exlager" },
      { :uuid, github: "avtobiff/erlang-uuid" },
      { :tempo, github: "selectel/tempo" },
    ]
  end
end
