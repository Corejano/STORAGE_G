defmodule StorageG.Repo do
  use Ecto.Repo,
    otp_app: :storage_g,
    adapter: Ecto.Adapters.Postgres
end
