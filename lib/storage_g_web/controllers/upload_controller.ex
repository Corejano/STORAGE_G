defmodule StorageGWeb.UploadController do
  @moduledoc """
  Принимает multipart-загрузку, раскладывает файл по папкам:
  uploads/<ext>/<size_bucket>/UUID_original.ext

  size_bucket:
    - small   (< 10 МБ)
    - medium  (< 500 МБ)
    - large   (>= 500 МБ)
  """

  use StorageGWeb, :controller

  require Logger
  alias StorageG.Repo
  alias StorageG.Files.File, as: FileRecord

  @upload_root Path.expand("uploads", File.cwd!())

  # ——— Вспомогательные функции ———

  # Бакет по размеру
  defp size_bucket(size) when is_integer(size) do
    cond do
      size < 10_000_000 -> "small"
      size < 500_000_000 -> "medium"
      true -> "large"
    end
  end

  # Расширение файла без точки, в нижнем регистре
  defp ext_of(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
    |> case do
      "" -> "bin"
      x -> x
    end
  end

  # Потоковое копирование из tmp в итоговый путь
  @dialyzer {:no_return, stream_copy!: 2}
  defp stream_copy!(src, dest) do
    File.mkdir_p!(Path.dirname(dest))

    # читаем chunks по ~1 МБ
    src_stream = File.stream!(src, [], 1_048_576)
    dest_stream = File.stream!(dest, [:write, :binary])

    src_stream
    |> Stream.into(dest_stream)
    |> Stream.run()

    :ok
  end

  # Проверка бизнес-лимита размера (из конфига)
  defp max_file_size() do
    Application.get_env(:storage_g, StorageG.Uploads)[:max_file_size] || 500_000_000
  end

  # ——— Экшены ———

  def create(
        conn,
        %{"file" => %Plug.Upload{filename: filename, path: tmp_path} = upload} = params
      ) do
    # Стат tmp-файла (его уже подготовил Plug)
    {:ok, stat} = File.stat(tmp_path)
    size = stat.size

    # Бизнес-валидация (не даём грузить больше лимита API)
    if size > max_file_size() do
      return_error(
        conn,
        :bad_request,
        "Файл слишком большой. Лимит API: #{max_file_size()} байт."
      )
    else
      # Раскладываем по папкам
      ext = ext_of(filename)
      bucket = size_bucket(size)

      unique_name = "#{Ecto.UUID.generate()}_#{filename}"
      save_dir = Path.join([@upload_root, ext, bucket])
      dest_path = Path.join(save_dir, unique_name)

      # Потоковая запись
      :ok = stream_copy!(tmp_path, dest_path)

      description = Map.get(params, "description", "Без описания")
      mime_type = upload.content_type || "application/octet-stream"

      # Метаданные
      file_attrs = %{
        filename: filename,
        path: dest_path,
        description: description,
        size: size,
        mime_type: mime_type,
        uploaded_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        hash: "pending",
        owner_id: Ecto.UUID.generate()
      }

      case %FileRecord{} |> FileRecord.changeset(file_attrs) |> Repo.insert() do
        {:ok, file} ->
          # ставим задачу в очередь files
          job = StorageG.Workers.ProcessFile.new(%{"file_id" => file.id})
          {:ok, _oban_job} = Oban.insert(StorageG.Oban, job)

          Logger.info("📦 Added job for file #{file.id} to Oban queue :files")

          Phoenix.PubSub.broadcast(StorageG.PubSub, "files:updates", {:new_file, file})

          json(conn, %{
            status: "ok",
            file_id: file.id,
            filename: file.filename,
            size: file.size,
            mime_type: file.mime_type,
            message: "Файл успешно загружен, задача на обработку отправлена"
          })

        {:error, changeset} ->
          return_error(conn, :bad_request, "Ошибка при сохранении файла", changeset.errors)
      end
    end
  end

  def create(conn, _params), do: return_error(conn, :bad_request, "Файл не найден в запросе")

  # ——— Унифицированные ответы об ошибке ———

  defp return_error(conn, status, message, details \\ nil) do
    body =
      if is_nil(details) do
        %{error: message}
      else
        %{error: message, details: details}
      end

    conn
    |> put_status(status)
    |> json(body)
  end
end
