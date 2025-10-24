defmodule StorageG.Workers.ProcessFile do
  @moduledoc """
  Воркер для фоновой обработки файла:
  - вычисляет SHA256-хэш;
  - обновляет запись в таблице files.
  """

  use Oban.Worker, queue: :files, max_attempts: 3

  alias StorageG.Repo
  alias StorageG.Files.File, as: FileRecord
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"file_id" => file_id}}) do
    case Repo.get(FileRecord, file_id) do
      nil ->
        Logger.warning("⚠️ File #{file_id} not found in DB")
        :discard

      file ->
        if File.exists?(file.path) do
          hash = calc_sha256(file.path)

          file
          |> Ecto.Changeset.change(hash: hash)
          |> Repo.update()

          Logger.info("✅ Hash updated for file #{file.filename}")
          :ok
        else
          Logger.error("❌ File #{file.path} missing on disk")
          :discard
        end
    end
  end

  defp calc_sha256(path) do
    {:ok, data} = File.read(path)
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end
