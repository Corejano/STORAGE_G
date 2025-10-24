defmodule StorageG.FilesTest do
  use StorageG.DataCase

  alias StorageG.Files

  describe "files" do
    alias StorageG.Files.File

    import StorageG.FilesFixtures

    @invalid_attrs %{size: nil, filename: nil, path: nil, description: nil, hash: nil, mime_type: nil, uploaded_at: nil, owner_id: nil}

    test "list_files/0 returns all files" do
      file = file_fixture()
      assert Files.list_files() == [file]
    end

    test "get_file!/1 returns the file with given id" do
      file = file_fixture()
      assert Files.get_file!(file.id) == file
    end

    test "create_file/1 with valid data creates a file" do
      valid_attrs = %{size: 42, filename: "some filename", path: "some path", description: "some description", hash: "some hash", mime_type: "some mime_type", uploaded_at: ~N[2025-10-21 08:50:00], owner_id: "7488a646-e31f-11e4-aace-600308960662"}

      assert {:ok, %File{} = file} = Files.create_file(valid_attrs)
      assert file.size == 42
      assert file.filename == "some filename"
      assert file.path == "some path"
      assert file.description == "some description"
      assert file.hash == "some hash"
      assert file.mime_type == "some mime_type"
      assert file.uploaded_at == ~N[2025-10-21 08:50:00]
      assert file.owner_id == "7488a646-e31f-11e4-aace-600308960662"
    end

    test "create_file/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Files.create_file(@invalid_attrs)
    end

    test "update_file/2 with valid data updates the file" do
      file = file_fixture()
      update_attrs = %{size: 43, filename: "some updated filename", path: "some updated path", description: "some updated description", hash: "some updated hash", mime_type: "some updated mime_type", uploaded_at: ~N[2025-10-22 08:50:00], owner_id: "7488a646-e31f-11e4-aace-600308960668"}

      assert {:ok, %File{} = file} = Files.update_file(file, update_attrs)
      assert file.size == 43
      assert file.filename == "some updated filename"
      assert file.path == "some updated path"
      assert file.description == "some updated description"
      assert file.hash == "some updated hash"
      assert file.mime_type == "some updated mime_type"
      assert file.uploaded_at == ~N[2025-10-22 08:50:00]
      assert file.owner_id == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_file/2 with invalid data returns error changeset" do
      file = file_fixture()
      assert {:error, %Ecto.Changeset{}} = Files.update_file(file, @invalid_attrs)
      assert file == Files.get_file!(file.id)
    end

    test "delete_file/1 deletes the file" do
      file = file_fixture()
      assert {:ok, %File{}} = Files.delete_file(file)
      assert_raise Ecto.NoResultsError, fn -> Files.get_file!(file.id) end
    end

    test "change_file/1 returns a file changeset" do
      file = file_fixture()
      assert %Ecto.Changeset{} = Files.change_file(file)
    end
  end
end
