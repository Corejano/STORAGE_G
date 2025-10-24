defmodule StorageG.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "files" do
    field :filename, :string
    field :path, :string
    field :description, :string
    field :size, :integer
    field :mime_type, :string
    field :hash, :string
    field :uploaded_at, :naive_datetime
    field :owner_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:filename, :path, :description, :size, :mime_type, :hash, :uploaded_at, :owner_id])
    |> validate_required([:filename, :path, :description, :size, :mime_type, :hash, :uploaded_at, :owner_id])
  end
end
