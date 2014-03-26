defmodule Cdp.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    current_user = String.strip System.cmd("whoami")
    env = Mix.env
    if Mix.env == :dev do
      env = :development
    end
    parse_url "ecto://#{current_user}:@localhost/cdp_#{env}"
  end
end

