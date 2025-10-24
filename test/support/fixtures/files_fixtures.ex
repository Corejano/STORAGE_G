defmodule StorageG.FilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StorageG.Files` context.
  """

  @doc """
  Generate a file.
  """
  def file_fixture(attrs \\ %{}) do
    {:ok, file} =
      attrs
      |> Enum.into(%{
        description: "some description",
        filename: "some filename",
        hash: "some hash",
        mime_type: "some mime_type",
        owner_id: "7488a646-e31f-11e4-aace-600308960662",
        path: "some path",
        size: 42,
        uploaded_at: ~N[2025-10-21 08:50:00]
      })
      |> StorageG.Files.create_file()

    file
  end
end
