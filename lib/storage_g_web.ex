defmodule StorageGWeb do
  @moduledoc """
  Точка входа для веб-интерфейса приложения (контроллеры, LiveView, компоненты и т.д.)
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  # --- Router ---
  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  # --- Controller ---
  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]
      import Plug.Conn
      import Gettext
      alias StorageGWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  # --- HTML helpers (для Layouts, компонентов и т.д.) ---
  def html do
    quote do
      use Phoenix.Component

      # HTML helpers
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.HTML.Tag

      # Компоненты и маршруты
      import StorageGWeb.CoreComponents
      unquote(verified_routes())
    end
  end

  # --- LiveView ---
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {StorageGWeb.Layouts, :root}

      import Phoenix.Component
      import Phoenix.LiveView
      import Phoenix.LiveView.Helpers
      import Phoenix.LiveView.Uploads
      import Phoenix.HTML.Form
      import Phoenix.HTML.Tag
      unquote(verified_routes())
    end
  end

  # --- Verified Routes ---
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StorageGWeb.Endpoint,
        router: StorageGWeb.Router,
        statics: StorageGWeb.static_paths()
    end
  end

  # --- Упрощённый макрос подключения ---
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
