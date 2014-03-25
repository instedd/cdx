defmodule CdpElixir.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    current_user = String.strip System.cmd("whoami")
    parse_url "ecto://#{current_user}:@localhost/cdp_development"
  end
end
