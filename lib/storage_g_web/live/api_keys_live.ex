defmodule StorageGWeb.ApiKeysLive do
  use StorageGWeb, :live_view
  alias StorageG.{Repo, ApiKeys.ApiKey}

  @impl true
  def mount(params, _session, socket) do
    # авторизация по ключу
    with key when not is_nil(key) <- params["key"],
         api_key <- Repo.get_by(ApiKey, key: key, active: true),
         true <- api_key.role in ["admin", "super"] do
      Phoenix.PubSub.subscribe(StorageG.PubSub, "keys:updates")

      {:ok,
       socket
       |> assign(:current_admin, api_key)
       |> assign(:keys, load_keys())
       |> assign(:form, %{})
       |> assign(:default_host, current_host())}
    else
      _ ->
        {:halt, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_info({:keys_updated}, socket) do
    {:noreply, assign(socket, :keys, load_keys())}
  end

  # ——— Переключение активности ———
  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    api_key = Repo.get!(ApiKey, id)

    unless api_key.role == "super" do
      Repo.update!(Ecto.Changeset.change(api_key, active: !api_key.active))
    end

    Phoenix.PubSub.broadcast(StorageG.PubSub, "keys:updates", {:keys_updated})
    {:noreply, assign(socket, :keys, load_keys())}
  end

  # ——— Удаление ключа ———
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    api_key = Repo.get!(ApiKey, id)

    unless api_key.role == "super" do
      Repo.delete!(api_key)
    end

    Phoenix.PubSub.broadcast(StorageG.PubSub, "keys:updates", {:keys_updated})
    {:noreply, assign(socket, :keys, load_keys())}
  end

  # ——— Создание нового ключа ———
  @impl true
  def handle_event("create", %{"owner" => owner, "host" => host, "role" => role}, socket) do
    key = Ecto.UUID.generate()

    Repo.insert(%ApiKey{
      key: key,
      owner: owner,
      host: host,
      role: role,
      active: true
    })

    Phoenix.PubSub.broadcast(StorageG.PubSub, "keys:updates", {:keys_updated})
    {:noreply, assign(socket, :keys, load_keys())}
  end

  # ——— Загрузка ключей без суперюзера ———
  defp load_keys do
    Repo.all(ApiKey)
    |> Enum.reject(fn key -> key.role == "super" end)
  end

  defp current_host do
    case Application.get_env(:storage_g, StorageGWeb.Endpoint)[:url] do
      %{host: host, port: port, scheme: scheme} ->
        "#{scheme}://#{host}:#{port}"

      _ ->
        "http://localhost:4000"
    end
  end

  # ——— Рендер таблицы ———
  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-5xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">🔐 Управление API-ключами</h1>

      <div class="bg-gray-50 p-4 rounded-lg mb-6 border border-gray-200">
        <h2 class="text-lg font-semibold mb-2">Создать новый ключ</h2>
        <form phx-submit="create" class="flex flex-wrap gap-2 items-center">
          <input
            type="text"
            name="owner"
            placeholder="Владелец"
            class="border rounded px-2 py-1"
            required
          />

          <input
            type="text"
            name="host"
            value={@default_host}
            class="border rounded px-2 py-1"
          />

          <select name="role" class="border rounded px-2 py-1">
            <option value="user">user</option>
            <option value="admin">admin</option>
          </select>

          <button class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">Создать</button>
        </form>

      </div>

      <table class="w-full border text-sm bg-white rounded shadow">
        <thead class="bg-gray-100">
          <tr>
            <th class="p-2 text-left">Владелец</th>
            <th class="p-2">Ключ</th>
            <th class="p-2">Активен</th>
            <th class="p-2">Хост</th>
            <th class="p-2">Роль</th>
            <th class="p-2">Действия</th>
          </tr>
        </thead>
        <tbody>
          <%= for k <- @keys do %>
            <tr class="border-t">
              <td class="p-2 font-semibold"><%= k.owner %></td>
              <td class="p-2 text-xs break-all"><%= k.key %></td>
              <td class="p-2 text-center"><%= if k.active, do: "✅", else: "❌" %></td>
              <td class="p-2"><%= k.host %></td>
              <td class="p-2"><%= k.role %></td>
              <td class="p-2 flex gap-2">
                <button phx-click="toggle" phx-value-id={k.id}
                  class="px-2 py-1 border rounded text-xs bg-gray-50 hover:bg-gray-100">
                  <%= if k.active, do: "Отключить", else: "Включить" %>
                </button>
                <%= if k.role != "super" do %>
                  <button phx-click="delete" phx-value-id={k.id}
                    class="px-2 py-1 border rounded text-xs bg-red-50 hover:bg-red-100 text-red-700">
                    Удалить
                  </button>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
