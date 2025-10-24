defmodule StorageG.ApiKeysFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StorageG.ApiKeys` context.
  """

  @doc """
  Generate a unique api_key key.
  """
  def unique_api_key_key, do: "some key#{System.unique_integer([:positive])}"

  @doc """
  Generate a api_key.
  """
  def api_key_fixture(attrs \\ %{}) do
    {:ok, api_key} =
      attrs
      |> Enum.into(%{
        active: true,
        key: unique_api_key_key(),
        owner: "some owner"
      })
      |> StorageG.ApiKeys.create_api_key()

    api_key
  end
end
