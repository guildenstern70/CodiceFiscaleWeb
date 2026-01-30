#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWebWeb.PageController do
  use CodiceWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
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
end
