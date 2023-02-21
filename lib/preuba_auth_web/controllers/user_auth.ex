defmodule PreubaAuthWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Phoenix.LiveView
  alias PreubaAuth.Accounts
  alias PreubaAuthWeb.Router.Helpers, as: Routes

  # MAKE THE REMEMBER ME COOKIE VALID FOR 60 DAYS

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_preuba_auth_web_user_remeber_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  LOGS THE USER IN

  THIS FUNCTION RENEWS THE ESSION ID AND CLEARS THE WHOLE SESSION TO AVOID FIXATION ATTACKS

  IT ALSO SETS A "live_socket_id" KEY IN THE SESSION, SO THAT LIVEVIEW SESSIONS ARE IDENTIFIED AND
  AUTOMATICALLY DISCONNECTED ON LOG OUT. (you can safely remove it if you not using LiveView)
  """

  def login_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    #user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "user_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_a_remember_me_cookie(token, params)
    |> redirect(to: Routes.page_path(conn, :show, user.id))
    #|> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_a_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_a_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # THIS FUNCTIONRENEWS THE SESSION ID AND ERASES THE WHOLE SESSION TO AVOID FIXATION ATTACKS.
  # IF THERE'S ANY DATA IN THE SESSION YOU MAY WANT TO PRESERVE AFTER login/logout,
  # YOU MUST EXPLICITLY FETCH THE SESSION DATA BEFORE CLEARING AND IMMEDIATELY SEE IT AFTER CLEARING.

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  LOGS THE USER OUT

  IT CLEARS ALL THE SESSION DATA FOR SAFETY
  """

  def logout_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      PreubaAuthWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  AUTHENTICATES THE USER BY LOOKING INTO THE SESSION AND REMEMBER ME
  """

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  # MIGRATING AUTH CONTROLLERS TO LIVEVIEW....
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(session, socket)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)

    case socket.assigns.current_user do
      nil ->
        {:halt, LiveView.redirect(socket, to: Routes.user_login_path(socket, :new))}

      _ ->
        {:cont, socket}
    end
  end

  def on_mount(:get_user_by_reset_password_token, params, _session, socket) do
    if socket.assigns.alive_action in [:edit, :update] do
      set_user_and_token(socket, params)
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(session, socket) do
    case session do
      %{"user_token" => user_token} ->
        LiveView.assign_new(socket, :current_user, fn ->
          Accounts.get_user_by_session_token(user_token)
        end)

      %{} ->
        LiveView.assign_new(socket, :current_user, fn -> nil end)
    end
  end

  defp set_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      {:cont, LiveView.assign(socket, user: user, token: token)}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "Reset password link is invalid or it has expired")
        |> LiveView.redirect(to: "/")

      {:halt, socket}
    end
  end

  @doc """
  FOR ROUTES THAT REQUIRE THE USER TO "NOT" BE AUTHENTICATED, PASS THROUGH =>
  """

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  FOR RPOUTES THAT REQUIRE THE USER TO BE AUTHENTICATED, PASS THROUGH =>
  """

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page")
      |> maybe_store_return_to()
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn) do
    conn
  end

  defp signed_in_path(_conn) do
    "/"
  end
end
