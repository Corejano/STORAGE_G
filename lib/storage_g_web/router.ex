defmodule StorageGWeb.Router do
  use StorageGWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {StorageGWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug StorageGWeb.Plugs.SaveKeyPlug
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # защищённый API
  pipeline :api_protected do
    plug :accepts, ["json"]
    plug StorageGWeb.Plugs.ApiAuth
  end

  scope "/", StorageGWeb do
    pipe_through :browser
    live "/dashboard", DashboardLive
    live "/keys", ApiKeysLive
    live "/admin", AdminDashboardLive
  end

  scope "/api", StorageGWeb do
    pipe_through(:api)
    get("/health", HealthController, :index)
  end

  scope "/api", StorageGWeb do
    pipe_through :api_protected

    post "/upload", UploadController, :create
    get "/files", FilesController, :index
    get "/file/:id", DownloadController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:storage_g, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard",
        metrics: StorageGWeb.Telemetry,
        oban: [StorageG.Oban]
      )

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
