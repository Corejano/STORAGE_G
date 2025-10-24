defmodule StorageG.Repo.Migrations.AddRoleAndUniqueOwnerToApiKeys do
  use Ecto.Migration

  def change do
    alter table(:api_keys) do
      add :role, :string, default: "user"
    end

    create unique_index(:api_keys, [:owner])
  end
end
