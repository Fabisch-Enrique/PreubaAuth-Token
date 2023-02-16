defmodule PreubaAuthWeb.PageController do
  use PreubaAuthWeb, :controller

  alias PreubaAuth.Accounts

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)
    render conn, "show.html", user: user
  end
end
