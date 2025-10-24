defmodule StorageGWeb.Hooks.SaveKeyLive do
  @moduledoc """
  Глобальный on_mount-хук для сохранения ?key=... в assigns.
  Работает при первом подключении и при реконнекте.
  """

  import Phoenix.Component, only: [assign: 3]
  alias Phoenix.LiveView.Socket

  def on_mount(:default, params, _session, %Socket{} = socket) do
    # пытаемся взять ключ из params или URL напрямую
    key =
      params["key"] ||
        extract_key_from_uri(socket)

    IO.puts("🔑 [SaveKeyLive] key = #{inspect(key)}")

    socket =
      if key do
        assign(socket, :api_key, key)
      else
        socket
      end

    {:cont, socket}
  end

  # достаём ключ напрямую из URL
  defp extract_key_from_uri(%Socket{} = socket) do
    case Map.get(socket, :host_uri) do
      %URI{query: query} when is_binary(query) ->
        query
        |> URI.decode_query()
        |> Map.get("key")

      _ ->
        nil
    end
  end
end
