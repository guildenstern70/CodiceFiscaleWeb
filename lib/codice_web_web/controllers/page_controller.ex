#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWebWeb.PageController do
  use CodiceWebWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/new")
  end

  # It shows a form to insert the data for the codice fiscale generation, 
  # and it also shows the generated codice fiscale if the data are present in the session.
  def new(conn, _params) do

    # See if a codice fiscale is present in the session, and if so, put it in the flash to be shown in the template.
    conn = case get_session(conn, :codice_fiscale) do
      nil -> conn
      codice_fiscale -> put_flash(conn, :info, "Generated codice fiscale: #{codice_fiscale}")
    end

    render(conn, :new)
  end

  # Creates the codice fiscale based on the data sent by the form, and it stores it in the session.
  def create(conn, data) do

    person = get_person_map_from_params(data)
    IO.inspect(person, label: "Person data from params")
    codice_fiscale = Codicefiscale.Computer.compute(CodiceWeb.Repo, person)
    IO.inspect(codice_fiscale, label: "Generated codice fiscale")
    conn
    |> put_session(:codice_fiscale, codice_fiscale)
    |> redirect(to: ~p"/new")

  end

  def set_theme(conn, %{"theme" => theme}) when is_binary(theme) do
    conn
    |> put_session(:theme, theme)
    |> put_resp_cookie("user_theme", theme, max_age: 31_536_000, http_only: false)
    |> send_resp(204, "")
  end

  def set_theme(conn, _params) do
    send_resp(conn, 400, "missing theme")
  end

  defp get_person_map_from_params(params) do
    %{name: Map.get(params, "name"),
    surname: Map.get(params, "surname"),
    gender: case Map.get(params, "gender") do
      "M" -> :male
      "F" -> :female
      _ -> nil
    end,
    birth_date: case Date.from_iso8601(Map.get(params, "birth_date")) do
      {:ok, date} -> date
      _ -> nil
    end,
    birth_place: Map.get(params, "birth_place")
  }
  end

end
