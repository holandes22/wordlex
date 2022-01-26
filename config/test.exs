import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wordlex, WordlexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+BsI7zG8/bIb8RYQtBXYWTGFOkmMwbYcNOnf83dzS5YdGOchD1h0EXWQLED2JGKN",
  server: false

# In test we don't send emails.
config :wordlex, Wordlex.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
