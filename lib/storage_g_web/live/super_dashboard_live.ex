defmodule StorageGWeb.SuperDashboardLive do
  use StorageGWeb, :live_view

  alias StorageG.{Repo, Files.File, ApiKeys.ApiKey}
  # import Ecto.Query

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
        |> Phoenix.LiveView.allow_upload(:file,
          accept: :any,
          max_entries: 5,
          # 2 ГБ
          max_file_size: 2_000_000_000
        )

      {:ok, socket}
    else
      _ -> {:halt, redirect(socket, to: "/")}
    end
  end

  # 🔄 новое событие при добавлении файла
  @impl true
  def handle_info({:new_file, file}, socket) do
    {:noreply, assign(socket, :files, [file | socket.assigns.files])}
  end

  # ✏️ редактировать описание
  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    file = Repo.get!(File, id)
    {:noreply, assign(socket, editing: file.id, edit_desc: file.description || "")}
  end

  # 💾 сохранить описание
  @impl true
  def handle_event("save_desc", %{"id" => id, "desc" => desc}, socket) do
    file = Repo.get!(File, id)
    Repo.update!(Ecto.Changeset.change(file, description: desc))

    Phoenix.PubSub.broadcast(StorageG.PubSub, @topic, {:new_file, file})

    {:noreply,
     socket
     |> assign(:files, Repo.all(File))
     |> assign(:editing, nil)
     |> assign(:edit_desc, "")}
  end

  # 🗑 удалить файл
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    file = Repo.get!(File, id)
    Repo.delete!(file)

    Phoenix.PubSub.broadcast(StorageG.PubSub, @topic, {:file_deleted, id})

    {:noreply, assign(socket, :files, Repo.all(File))}
  end

  # 🔍 фильтр
  @impl true
  def handle_event("filter", %{"q" => q}, socket) do
    {:noreply, assign(socket, :filter, q)}
  end

  # 📤 обработка загрузки файла
  @impl true
  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        filename = entry.client_name
        mime = entry.client_type
        size = File.stat!(path).size

        dest_path = Path.join(["uploads", filename])
        File.mkdir_p!("uploads")
        File.cp!(path, dest_path)

        file =
          Repo.insert!(%File{
            filename: filename,
            size: size,
            mime_type: mime,
            description: "Загружено вручную",
            path: dest_path,
            hash: "pending",
            owner_id: socket.assigns.owner,
            uploaded_at: NaiveDateTime.utc_now()
          })

        Phoenix.PubSub.broadcast(StorageG.PubSub, @topic, {:new_file, file})

        {:ok, dest_path}
      end)

    {:noreply,
     socket
     |> assign(:uploaded_files, uploaded_files)
     |> assign(:files, Repo.all(File))}
  end

  # ——— render ———
  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto bg-gradient-to-b from-white to-gray-50 rounded-xl shadow-lg">
      <h1 class="text-3xl font-bold mb-6 text-gray-800">🛠 Super Dashboard</h1>
      <div class="mb-4 text-gray-600">
        Суперпользователь: <b><%= @owner %></b>
      </div>

      <!-- 🔼 Форма загрузки -->
      <div class="mb-8 border border-gray-200 rounded-lg p-4 bg-gray-50">
        <h2 class="text-lg font-semibold mb-3">📤 Загрузить новый файл</h2>

        <form phx-submit="upload" phx-change="validate">
          <.live_file_input upload={@uploads.file} class="mb-3" />
          <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Загрузить
          </button>
        </form>
      </div>

      <div class="mb-4">
        <input type="text" name="q" phx-change="filter" value={@filter}
          placeholder="Поиск по имени..." class="border rounded px-3 py-2 w-96 shadow-sm" />
      </div>

      <table class="min-w-full text-sm border border-gray-200 rounded shadow">
        <thead class="bg-gray-100 text-gray-700">
          <tr>
            <th class="p-2 text-left">Имя</th>
            <th class="p-2 text-left">Описание</th>
            <th class="p-2 text-left">Размер</th>
            <th class="p-2 text-left">Тип</th>
            <th class="p-2 text-left">Дата</th>
            <th class="p-2 text-left">Действия</th>
          </tr>
        </thead>
        <tbody>
          <%= for f <- @files |> Enum.filter(&(String.contains?(String.downcase(&1.filename), String.downcase(@filter)))) do %>
            <tr class="border-t hover:bg-gray-50">
              <td class="p-2"><%= f.filename %></td>

              <td class="p-2">
                <%= if @editing == f.id do %>
                  <form phx-submit="save_desc" phx-value-id={f.id}>
                    <input type="text" name="desc" value={@edit_desc}
                      class="border rounded px-2 py-1 text-sm w-64" />
                    <button class="ml-2 px-2 py-1 text-xs bg-blue-600 text-white rounded">💾</button>
                  </form>
                <% else %>
                  <%= f.description || "—" %>
                  <button phx-click="edit" phx-value-id={f.id}
                    class="ml-2 text-xs text-blue-500 hover:underline">✏️</button>
                <% end %>
              </td>

              <td class="p-2"><%= div(f.size, 1024) %> KB</td>
              <td class="p-2"><%= f.mime_type %></td>
              <td class="p-2"><%= f.inserted_at %></td>

              <td class="p-2">
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
    """
  end
end
