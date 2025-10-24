defmodule StorageGWeb.DownloadController do
  use StorageGWeb, :controller

  alias StorageG.Repo
  alias StorageG.Files.File, as: FileRecord

  @doc """
  GET /api/file/:id
  Отдаёт файл полностью или по диапазону (Range).
  """
  def show(conn, %{"id" => id}) do
    with %FileRecord{} = rec <- Repo.get(FileRecord, id),
         true <- File.exists?(rec.path),
         {:ok, %File.Stat{size: size}} <- File.stat(rec.path) do
      conn = put_resp_header(conn, "accept-ranges", "bytes")
      conn = put_resp_header(conn, "content-type", rec.mime_type || "application/octet-stream")

      case get_req_header(conn, "range") do
        [<<"bytes=", range::binary>>] ->
          case parse_range(range, size) do
            {:ok, start_pos, end_pos} ->
              length = end_pos - start_pos + 1

              conn
              |> put_status(:partial_content)
              |> put_resp_header("content-range", "bytes #{start_pos}-#{end_pos}/#{size}")
              |> send_file(206, rec.path, start_pos, length)

            :error ->
              conn
              |> put_status(:requested_range_not_satisfiable)
              |> put_resp_header("content-range", "bytes */#{size}")
              |> json(%{error: "Invalid Range"})
          end

        _ ->
          send_file(conn, 200, rec.path)
      end
    else
      nil ->
        send_resp(conn, 404, ~s({"error":"File not found"}))

      false ->
        send_resp(conn, 404, ~s({"error":"File missing on disk"}))

      {:error, _} ->
        send_resp(conn, 500, ~s({"error":"Cannot access file"}))
    end
  end

  # --- helpers ---

  defp parse_range(range, size) do
    case String.split(range, "-") do
      [start_s, end_s] ->
        {s_ok?, start} = parse_int(start_s)
        {e_ok?, stop} = parse_int(end_s)

        cond do
          s_ok? and e_ok? and start <= stop and stop < size ->
            {:ok, start, stop}

          s_ok? and not e_ok? and start < size ->
            {:ok, start, size - 1}

          not s_ok? and e_ok? ->
            # bytes=-N
            n = stop
            if n > 0, do: {:ok, max(size - n, 0), size - 1}, else: :error

          true ->
            :error
        end

      _ ->
        :error
    end
  end

  defp parse_int(""), do: {false, 0}

  defp parse_int(str) do
    case Integer.parse(str) do
      {n, ""} when n >= 0 -> {true, n}
      _ -> {false, 0}
    end
  end
end
