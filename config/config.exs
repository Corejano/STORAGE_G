# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :storage_g,
  ecto_repos: [StorageG.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :storage_g, StorageGWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: StorageGWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StorageG.PubSub,
  live_view: [signing_salt: "xcQt9UlP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :storage_g, StorageG.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Обан — базовая конфигурация (очереди и плагин очистки)
config :storage_g, :oban,
  repo: StorageG.Repo,
  queues: [default: 10, files: 5],
  # чистит старые задания
  plugins: [Oban.Plugins.Pruner],
  name: StorageG.Oban

config :storage_g, StorageG.Uploads,
  # синхронизируем с endpoint.ex
  max_request_length: 2_500_000_000,
  # 500 МБ — бизнес-лимит API (можно менять)
  max_file_size: 500_000_000

# config :esbuild,
#   version: "0.21.5",
#   default: [
#     args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
#     cd: Path.expand("../assets", __DIR__),
#     env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
#   ]

# config :tailwind,
#   version: "3.3.3",
#   default: [
#     args: ~w(
#       --config=tailwind.config.js
#       --input=css/app.css
#       --output=../priv/static/assets/app.css
#     ),
#     cd: Path.expand("../assets", __DIR__)
#   ]
