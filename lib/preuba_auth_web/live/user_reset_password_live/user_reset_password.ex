defmodule PreubaAuthWeb.UserResetPasswordLive.UserResetPassword do
  use PreubaAuthWeb, :live_view

  alias PreubaAuth.Accounts

  on_mount {PreubaAuthWeb.UserAuth, :get_user_by_reset_password_token}

  def mount(_params, _session, socket) do
    if socket.assigns.live_action in [:edit, :update] do
      changeset = Accounts.change_user_password(socket.assigns.user)

      socket
      |> assign(:changeset, changeset)

      {:ok,
        socket
        |> assign(:changeset, changeset)}
    else
      {:ok, socket}
    end
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Password Reset Successfully")
        |> redirect(to: Routes.user_session_path(socket, :new))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)}
    end
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(socket, :edit, &1))

      socket
      |> put_flash(:info, "If your email is in our system, you will receive instructions to reset your password shortly")
      |> redirect(to: "/")
    end
  end
end
