import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :preuba_auth, PreubaAuth.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "preuba_auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :preuba_auth, PreubaAuthWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "aTy5/1t6SEhp6U6Tbtt8+uQnC8SJskTHw8k+LOhjrFWBkV+8sub0HvmgNlgaJaOZ",
  server: false

# In test we don't send emails.
config :preuba_auth, PreubaAuth.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
