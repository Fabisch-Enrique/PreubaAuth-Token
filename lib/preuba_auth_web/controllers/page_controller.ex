defmodule PreubaAuthWeb.PageController do
  use PreubaAuthWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
