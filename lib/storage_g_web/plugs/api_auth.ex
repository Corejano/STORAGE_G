defmodule StorageGWeb.Plugs.ApiAuth do
  import Plug.Conn
  alias StorageG.{Repo, ApiKeys.ApiKey}

  def init(opts), do: opts

  def call(conn, _opts) do
    key =
      case get_req_header(conn, "authorization") do
        ["ApiKey " <> k] -> k
        _ -> conn.params["key"]
      end

    if valid_key?(key) do
      assign(conn, :api_key, key)
    else
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end

  defp valid_key?(nil), do: false
  defp valid_key?(key), do: Repo.get_by(ApiKey, key: key, active: true)
end
