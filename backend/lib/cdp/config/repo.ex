defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    current_user = String.strip System.cmd("whoami")
    env = Mix.env
    case Mix.env do
      :dev ->
        parse_url "ecto://#{current_user}:@localhost/cdp_development"
      :test ->
        parse_url "ecto://#{current_user}:@localhost/cdp_test"
      :prod ->
        parse_url "ecto://#{current_user}:#{current_user}@localhost/cdp_production"
    end
  end
end

