defmodule PreubaAuth.Repo do
  use Ecto.Repo,
    otp_app: :preuba_auth,
    adapter: Ecto.Adapters.Postgres
end
