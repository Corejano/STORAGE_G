# ------------- lib/storage_g_web/controllers/health_controller.ex ---------
defmodule StorageGWeb.HealthController do
  use StorageGWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "storageG",
      timestamp: DateTime.utc_now()
    })
  end
end
