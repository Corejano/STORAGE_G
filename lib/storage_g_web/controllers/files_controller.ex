defmodule StorageGWeb.FilesController do
  @moduledoc """
  Возвращает список загруженных файлов.
  """

  use StorageGWeb, :controller

  alias StorageG.Repo
  alias StorageG.Files.File, as: FileRecord

  @doc "Возврат списка файлов"
  def index(conn, _params) do
    files =
      Repo.all(FileRecord)
      |> Enum.map(fn f ->
        %{
          id: f.id,
          filename: f.filename,
          description: f.description,
          size: f.size,
          mime_type: f.mime_type,
          uploaded_at: f.uploaded_at,
          url: "/api/file/#{f.id}"
        }
      end)

    json(conn, %{files: files})
  end
end
