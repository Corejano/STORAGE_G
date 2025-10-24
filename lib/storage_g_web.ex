defmodule StorageGWeb do
  @moduledoc """
  The entrypoint for defining your web interface,
  such as controllers, components, channels, and so on.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]
      import Plug.Conn
      use Gettext, backend: StorageGWeb.Gettext
      unquote(verified_routes())
    end
  end

  # ⬇️ ВАЖНО: никаких Phoenix.HTML.Tag
  def html do
    quote do
      use Phoenix.Component
      import Phoenix.HTML

      # import Phoenix.HTML.Form  # можно подключить, если где-то нужны form_* хелперы
      alias Phoenix.LiveView.JS, as: JS
      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {StorageGWeb.Layouts, :root}

      import Phoenix.Component

      # НЕ импортируем Phoenix.LiveView.Helpers — в 0.20+ почти всё уже в Phoenix.Component
      alias Phoenix.LiveView.JS, as: JS
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StorageGWeb.Endpoint,
        router: StorageGWeb.Router,
        statics: StorageGWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
