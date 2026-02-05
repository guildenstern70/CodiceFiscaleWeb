#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWebWeb.ComuniController do
  use CodiceWebWeb, :controller

  def index(conn, %{"q" => q}) when is_binary(q) do
    q = String.trim(q)

    results =
      if String.length(q) < 3 do
        []
      else
        Codicefiscale.Comuni.get_all_comuni(CodiceWeb.Repo)
        |> Enum.filter(fn comune ->
          String.downcase(comune) |> String.starts_with?(String.downcase(q))
        end)
        |> Enum.take(50)
      end

    json(conn, results)
  end

  def index(conn, _params) do
    json(conn, [])
  end
end
