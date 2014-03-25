defmodule CdpElixir.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    parse_url "ecto://asterite-manas:@localhost/cdp_development"
  end
end
