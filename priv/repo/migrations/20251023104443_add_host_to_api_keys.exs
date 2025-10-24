defmodule StorageG.Repo.Migrations.AddHostToApiKeys do
  use Ecto.Migration

  def change do
    alter table(:api_keys) do
      add :host, :string, default: "http://localhost:4000"
    end
  end
end
