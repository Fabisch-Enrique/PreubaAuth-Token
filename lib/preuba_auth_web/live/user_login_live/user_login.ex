defmodule PreubaAuthWeb.UserLoginLive.UserLogin do
  use PreubaAuthWeb, :live_view

  alias PreubaAuth.Accounts

  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(error_message: nil)
      |> assign(trigger_submit: false)}
  end

  def handle_event("log_in", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params

    if Accounts.get_user_by_email_and_password(email, password) do
      {:noreply,
        socket
        |> assign(trigger_submit: true)}
    else
      #IN ORDER TO PREVENT USER ENUMERATION ATTACKS, DO NOT DISCLOSE WHETHER THE EMAIL IS REGISTERED/NOT
      {:noreply,
        socket
        |> assign(:error_message, "Invalid Email or Password")}
    end
  end
end
