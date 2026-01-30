#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWebWeb.PageController do
  use CodiceWebWeb, :controller

  def home(conn, _params) do

    # Get current migration
    {_num_rows, result} = CodiceWeb.Repo.query("SELECT * FROM schema_migrations LIMIT 1")
    [latest_migration | _] = result.rows
    IO.inspect(latest_migration, label: "Database latest migration")
    render(conn, :home)
  end
end
