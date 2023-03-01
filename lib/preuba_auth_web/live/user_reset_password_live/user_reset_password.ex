defmodule PruebaAuthWeb.UserResetPasswordLive.UserResetPassword do
  use PreubaAuthWeb, :live_view

  alias PruebaAuth.Accounts

  on_mount {PruebaAuthWeb.UserAuth, :get_user_by_reset_password_token}

  def render(%{live_action: :new} = assigns) do
    ~H"""

    <h1>Forgot your password?</h1>

    <.form let={f} for={:user} phx-submit={"send_email"}>

      <%= label f, :email %>
      <%= email_input f, :email, required: true %>

      <div>
        <%= submit "Send instructions to reset password" %>
      </div>

    </.form>

    """
  end

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <h1>Reset password</h1>

    <.form let={f} for={@changeset} phx-submit={"reset_password"}>

      <%= if @changeset.action do %>

        <div class="alert alert-danger">
          <p>Oops, something went wrong! Please check the errors below.</p>
        </div>

      <% end %>
      <%= label f, :password, "New password" %>
      <%= password_input f, :password, required: true %>
      <%= error_tag f, :password %>
      <%= label f, :password_confirmation, "Confirm new password" %>
      <%= password_input f, :password_confirmation, required: true %>
      <%= error_tag f, :password_confirmation %>

      <div>
        <%= submit "Reset password" %>
      </div>

    </.form>
    """
  end

  def mount(_params, _session, socket) do
    if socket.assigns.live_action in [:edit, :update] do
      changeset = Accounts.change_user_password(socket.assigns.user)
      assign(socket, :changeset, changeset)
      {:ok, assign(socket, :changeset, changeset)}
    else
      {:ok, socket}
    end
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.user_login_path(socket, :new))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &Routes.user_reset_password_url(socket, :edit, &1)
      )
    end

    socket
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end
end
