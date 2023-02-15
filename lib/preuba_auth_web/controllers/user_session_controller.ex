defmodule PreubaAuthWeb.UserSessionController do
  use PreubaAuthWeb, :controller

  alias PreubaAuth.Accounts
  alias PreubaAuthWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.login_user(conn, user, user_params)
    else
      #IN ORDER TO PREVENT ENUMERATION ATTACKS, WE DON'T DISCLOSE WHETHER THE EMAIL IS REGISTERED
      conn
      |> put_flash(:error, "Invalid email or password")
      |> redirect(to: Routes.user_login_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfuly")
    |> UserAuth.logout_user()
  end
end
