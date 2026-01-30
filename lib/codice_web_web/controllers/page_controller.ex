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
end
