#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWebWeb.PageControllerTest do
  use CodiceWebWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/new"
  end

  test "GET /new", %{conn: conn} do
    conn = get(conn, ~p"/new")
    html = html_response(conn, 200)
    assert html =~ "Codice Fiscale"
    assert html =~ ~s(<button type="reset" id="btn-annulla" class="btn">Annulla</button>)
  end
end
