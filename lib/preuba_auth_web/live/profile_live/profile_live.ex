defmodule PreubaAuthWeb.ProfileLive do
  use PreubaAuthWeb, :live_view

  on_mount {PreubaAuthWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end
