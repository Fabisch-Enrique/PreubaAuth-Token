defmodule PreubaAuthWeb.UserRegistrationLive.UserRegistration do
  use PreubaAuthWeb, :live_view

  alias PreubaAuth.Accounts
  alias PreubaAuth.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok,
      socket
      |> assign(changeset: changeset)
      |> assign(trigger_submit: false)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} = Accounts.deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(socket, :edit, &1))
        socket =
          socket
          |> put_flash(:info, "User Created Successfully.")
          |> assign(:trigger_submit, true)

          {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    {:noreply,
      socket
      |> assign(:changeset, changeset)}
  end
end
