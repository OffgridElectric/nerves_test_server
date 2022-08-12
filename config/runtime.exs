import Config

config :nerves_test_server, NervesTestServerWeb.Endpoint,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :nerves_test_server, NervesTestServer.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

case System.get_env("DEBUG", "0") do
  "0" ->
    config :logger, level: :info

  "1" ->
    config :logger, level: :debug
end

config :circle_ci,
  token: System.get_env("NERVES_CIRCLECI_TOKEN")

config :tentacat,
  token: System.get_env("NERVES_GITHUB_TOKEN")
