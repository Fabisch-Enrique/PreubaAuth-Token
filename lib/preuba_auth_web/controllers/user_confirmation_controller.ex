defmodule PreubaAuthWeb.UserConfirmationController do
  use PreubaAuthWeb, :controller

  alias PreubaAuth.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not yet been confirmed, " <>
        "You will receive an email with instructions shortly"
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "User confirmed Successfully")
        |> redirect(to: "/")

      :error ->
        # IF THERE'S A CURRENT USER AND THE ACCOUNT WAS ALREADY CONFIRMED, CHANCES ARE,
        # THE CONFIRMATION LINK HAS ALREADY BEEN VISITED, EITHER BY (some automation or the user themselves)
        # SO, WE REDIRECT WITHOUT A WARNING MESSAGE.

        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "User Confirmatiomn  Link is invalid or expired")
            |> redirect(to: "/")
        end
    end
  end
end
