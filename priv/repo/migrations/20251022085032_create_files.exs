defmodule StorageG.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :path, :string
      add :description, :text
      add :size, :integer
      add :mime_type, :string
      add :hash, :string
      add :uploaded_at, :naive_datetime
      add :owner_id, :uuid

      timestamps(type: :utc_datetime)
    end
  end
end
