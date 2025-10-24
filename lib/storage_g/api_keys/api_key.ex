defmodule StorageG.ApiKeys.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field(:key, :string)
    field(:owner, :string)
    field(:active, :boolean, default: true)
    field :host, :string, default: "http://localhost:4000"
    # user | admin | super
    field :role, :string, default: "user"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:key, :owner, :active, :host, :role])
    |> validate_required([:key, :owner, :active])
    |> unique_constraint(:owner)
  end
end
