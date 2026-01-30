#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWeb.Repo do
  use Ecto.Repo,
    otp_app: :codice_web,
    adapter: Ecto.Adapters.SQLite3
end
