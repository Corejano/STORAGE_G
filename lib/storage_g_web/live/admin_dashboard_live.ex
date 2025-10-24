defmodule StorageGWeb.AdminDashboardLive do
  use StorageGWeb, :live_view

  alias StorageG.{Repo, Files.File, ApiKeys.ApiKey}

  @topic "files:updates"

  @impl true
  def mount(params, _session, socket) do
    with key when not is_nil(key) <- params["key"],
         api_key <- Repo.get_by(ApiKey, key: key, active: true),
         true <- api_key.role == "super" do
      Phoenix.PubSub.subscribe(StorageG.PubSub, @topic)

      socket =
        socket
        |> assign(:files, Repo.all(File))
        |> assign(:api_key, api_key.key)
        |> assign(:owner, api_key.owner)
        |> assign(:editing, nil)
        |> assign(:edit_desc, "")
        |> assign(:filter, "")

      {:ok, socket}
    else
      _ -> {:halt, redirect(socket, to: "/")}
    end
  end

  # 🔄 обновления по PubSub
  @impl true
  def handle_info({:new_file, file}, socket),
    do: {:noreply, assign(socket, :files, [file | socket.assigns.files])}

  @impl true
  def handle_info({:file_updated, updated_file}, socket),
    do:
      {:noreply, assign(socket, :files, update_file_in_list(socket.assigns.files, updated_file))}

  @impl true
  def handle_info({:file_deleted, id}, socket),
    do: {:noreply, assign(socket, :files, Enum.reject(socket.assigns.files, &(&1.id == id)))}

  # ✏️ редактирование описания
  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    file = Repo.get!(File, id)
    {:noreply, assign(socket, editing: file.id, edit_desc: file.description || "")}
  end

  # 💾 сохранение описания
  @impl true
  def handle_event("save_desc", %{"id" => id, "desc" => desc}, socket) do
    file = Repo.get!(File, id)
    {:ok, updated_file} = Repo.update(Ecto.Changeset.change(file, description: desc))
    Phoenix.PubSub.broadcast(StorageG.PubSub, @topic, {:file_updated, updated_file})

    {:noreply,
     socket
     |> assign(:files, update_file_in_list(socket.assigns.files, updated_file))
     |> assign(:editing, nil)
     |> assign(:edit_desc, "")}
  end

  # 🗑 удалить файл
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    file = Repo.get!(File, id)
    Repo.delete!(file)
    Phoenix.PubSub.broadcast(StorageG.PubSub, @topic, {:file_deleted, id})
    {:noreply, assign(socket, :files, Enum.reject(socket.assigns.files, &(&1.id == id)))}
  end

  # 🔍 фильтр
  @impl true
  def handle_event("filter", %{"q" => q}, socket),
    do: {:noreply, assign(socket, :filter, q)}

  # 🧠 утилита обновления списка
  defp update_file_in_list(files, updated_file),
    do: Enum.map(files, fn f -> if f.id == updated_file.id, do: updated_file, else: f end)

  # ——— HTML рендер ———
  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto bg-linear-to-b from-white to-gray-50 rounded-xl shadow-lg">
      <h1 class="text-3xl font-bold mb-6 text-gray-800">🗂 Панель администратора</h1>
      <div class="mb-4 text-gray-600">
        Суперпользователь: <b><%= @owner %></b>
      </div>

      <!-- 🔍 Фильтр -->
      <div class="mb-4">
        <input type="text" name="q" phx-change="filter" value={@filter}
          placeholder="Поиск по имени..." class="border rounded px-3 py-2 w-96 shadow-sm" />
      </div>

      <!-- 📄 Таблица -->
      <div class="overflow-x-auto">
        <table class="min-w-full text-sm border border-gray-200 rounded shadow table-fixed">
          <thead class="bg-gray-100 text-gray-700">
            <tr>
              <th class="w-1/5 p-2 text-left">Имя файла</th>
              <th class="w-2/5 p-2 text-left">Описание</th>
              <th class="w-1/10 p-2 text-left">Размер</th>
              <th class="w-1/10 p-2 text-left">Тип</th>
              <th class="w-1/10 p-2 text-left">Дата</th>
              <th class="w-1/10 p-2 text-center">Редактировать</th>
              <th class="w-1/10 p-2 text-center">Удалить</th>
            </tr>
          </thead>

          <tbody>
            <%= for f <- @files
                    |> Enum.filter(&(String.contains?(String.downcase(&1.filename),
                            String.downcase(@filter)))) do %>
              <tr class="border-t hover:bg-gray-50 align-middle">
                <td class="p-2 truncate" title={f.filename}><%= f.filename %></td>

                <td class="p-2">
                  <%= if @editing == f.id do %>
                    <form phx-submit="save_desc" phx-value-id={f.id} class="flex items-center gap-2">
                      <input type="text" name="desc" value={@edit_desc}
                        class="border rounded px-2 py-1 text-sm w-full" />
                      <button class="px-2 py-1 text-xs bg-green-600 text-white rounded">💾</button>
                    </form>
                  <% else %>
                    <span class="block truncate" title={f.description}><%= f.description || "—" %></span>
                  <% end %>
                </td>

                <td class="p-2 whitespace-nowrap"><%= div(f.size, 1024) %> KB</td>
                <td class="p-2 whitespace-nowrap"><%= f.mime_type %></td>
                <td class="p-2 whitespace-nowrap"><%= f.inserted_at %></td>

                <td class="p-2 text-center">
                  <%= if @editing == f.id do %>
                    <span class="text-gray-400 text-xs">ввод...</span>
                  <% else %>
                    <button phx-click="edit" phx-value-id={f.id}
                      class="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded hover:bg-blue-200">
                      ✏️ Редактировать
                    </button>
                  <% end %>
                </td>

                <td class="p-2 text-center">
                  <button phx-click="delete" phx-value-id={f.id}
                    class="px-2 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200">
                    🗑 Удалить
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
