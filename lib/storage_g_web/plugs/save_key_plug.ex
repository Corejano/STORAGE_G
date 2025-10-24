defmodule StorageGWeb.Plugs.SaveKeyPlug do
  @moduledoc """
  Сохраняет параметр ?key=... в cookie и добавляет его в conn.assigns.
  """

  import Plug.Conn

  @cookie_name "_storageg_api_key"

  def init(opts), do: opts

  def call(conn, _opts) do
    key_param = conn.params["key"]
    key_cookie = conn.cookies[@cookie_name]
    key = key_param || key_cookie

    conn =
      if key_param && key_param != key_cookie do
        put_resp_cookie(conn, @cookie_name, key_param, max_age: 86_400)
      else
        conn
      end

    assign(conn, :api_key, key)
  end
end
