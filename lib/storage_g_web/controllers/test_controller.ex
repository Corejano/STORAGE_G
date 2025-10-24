defmodule StorageGWeb.TestController do
  use StorageGWeb, :controller

  def check(conn, _params) do
    json(conn, %{status: "ok", message: "API key valid"})
  end
end
