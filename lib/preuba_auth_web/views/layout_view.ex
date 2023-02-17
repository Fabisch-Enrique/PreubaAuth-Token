defmodule PreubaAuthWeb.LayoutView do
  use PreubaAuthWeb, :view

  @doc """
  Phoenix LiveDashboard is available only in development by default,
  So we instruct Elixir to not warn if the dashboard route is missing.
  """
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}
end
