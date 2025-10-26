defmodule StorageGWeb.DashboardLive do
  @moduledoc """
  Современный дашборд пользователя — таблица файлов с фильтром, сортировкой и пагинацией.
  """

  use StorageGWeb, :live_view
  alias StorageG.{Repo, Files.File, ApiKeys.ApiKey}

  @topic "files:updates"
  @page_size 10

  # ——— mount ———
  @impl true
  def mount(params, _session, socket) do
    case authorize(params["key"]) do
      {:ok, owner, api_key, host} ->
        Phoenix.PubSub.subscribe(StorageG.PubSub, @topic)
        files = Repo.all(File)

        {:ok,
         socket
         |> assign(:files, files)
         |> assign(:filtered, files)
         |> assign(:filter, "")
         |> assign(:api_key, api_key)
         |> assign(:owner, owner)
         |> assign(:host, host)
         |> assign(:sort_field, :inserted_at)
         |> assign(:sort_dir, :desc)
         |> assign(:page, 1)
         |> assign(:page_size, @page_size)}

      {:error, _} ->
        {:halt, redirect(socket, to: "/")}
    end
  end

  # ——— handle_info ———
  @impl true
  def handle_info({:new_file, file}, socket) do
    files = [file | socket.assigns.files]

    {:noreply,
     assign(socket, :files, files) |> assign(:filtered, apply_filter_sort(socket, files))}
  end

  # ——— handle_event: filter ———
  @impl true
  def handle_event("filter", %{"q" => q}, socket) do
    {:noreply,
     socket
     |> assign(:filter, q)
     |> assign(:page, 1)
     |> assign(:filtered, apply_filter_sort(socket))}
  end

  # ——— handle_event: sort ———
  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)

    dir =
      if socket.assigns.sort_field == field_atom and socket.assigns.sort_dir == :asc,
        do: :desc,
        else: :asc

    {:noreply,
     socket
     |> assign(:sort_field, field_atom)
     |> assign(:sort_dir, dir)
     |> assign(:filtered, apply_filter_sort(socket))}
  end

  # ——— handle_event: pagination ———
  @impl true
  def handle_event("page", %{"to" => dir}, socket) do
    new_page =
      case dir do
        "prev" ->
          max(socket.assigns.page - 1, 1)

        "next" ->
          if socket.assigns.page * @page_size < length(socket.assigns.filtered),
            do: socket.assigns.page + 1,
            else: socket.assigns.page
      end

    {:noreply, assign(socket, :page, new_page)}
  end

  # ——— render ———
  @impl true
  def render(assigns) do
    ~H"""
    <div id="dashboard" class="max-w-7xl mx-auto bg-white rounded-2xl shadow-lg border border-gray-100 p-10 space-y-8">
      <!-- 🔹 Инфо-блок -->
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <p class="text-gray-700 text-sm">Вы вошли как:</p>
          <p class="text-lg font-semibold text-gray-900"><%= @owner %></p>
        </div>
        <div class="flex flex-col items-start sm:items-end">
          <p class="text-gray-700 text-sm">Ваш API-ключ:</p>
          <code class="bg-white border border-gray-300 rounded px-2 py-1 text-gray-800 text-sm shadow-sm"><%= @api_key %></code>
          <p class="text-xs text-gray-500 mt-1">Скопируйте ссылку из таблицы, чтобы использовать файл в других сервисах</p>
        </div>
      </div>

      <!-- 🔍 панель фильтра и пагинации -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4 border-b border-gray-200">
        <input
          type="text"
          name="q"
          value={@filter}
          phx-change="filter"
          placeholder="Поиск по имени или описанию..."
          class="border border-gray-300 rounded-lg px-4 py-2 w-full sm:w-96 shadow-sm focus:ring-2 focus:ring-blue-300 focus:outline-none"
        />

        <div class="flex items-center gap-2">
          <button phx-click="page" phx-value-to="prev"
            class="px-4 py-1.5 border rounded-lg bg-white hover:bg-gray-100 text-sm">← Назад</button>
          <button phx-click="page" phx-value-to="next"
            class="px-4 py-1.5 border rounded-lg bg-white hover:bg-gray-100 text-sm">Вперёд →</button>
          <span class="text-sm text-gray-500 ml-2">
            Страница <%= @page %> из <%= total_pages(@filtered, @page_size) %>
          </span>
        </div>
      </div>

      <!-- 📊 таблица -->
      <div class="overflow-x-auto w-full rounded-lg shadow border border-gray-200">
        <table class="min-w-full text-sm text-left border-collapse">
          <thead class="bg-linear-to-r from-blue-500 to-blue-600 text-white uppercase text-xs tracking-wider">
            <tr>
              <th class="p-3 w-[22%] cursor-pointer text-left" phx-click="sort" phx-value-field="filename">Имя файла</th>
              <th class="p-3 w-[28%] text-left">Описание</th>
              <th class="p-3 w-[10%] cursor-pointer text-left" phx-click="sort" phx-value-field="size">Размер</th>
              <th class="p-3 w-[12%] text-left">Тип</th>
              <th class="p-3 w-[15%] cursor-pointer text-left" phx-click="sort" phx-value-field="inserted_at">Дата</th>
              <th class="p-3 w-[20%] text-left">Ссылка</th>
            </tr>
          </thead>

          <tbody class="bg-white divide-y divide-gray-100">
            <%= for f <- current_page(@filtered, @page, @page_size) do %>
              <tr class="hover:bg-blue-50 transition">
                <td class="p-3 truncate font-medium text-gray-900" title={f.filename}><%= f.filename %></td>
                <td class="p-3 truncate text-gray-600" title={f.description}><%= f.description || "—" %></td>
                <td class="p-3 whitespace-nowrap text-gray-600"><%= format_size(f.size) %></td>
                <td class="p-3 whitespace-nowrap text-gray-600"><%= f.mime_type %></td>
                <td class="p-3 whitespace-nowrap text-gray-600"><%= f.inserted_at %></td>
                <td class="p-3">
                  <% link = "#{@host}/api/file/#{f.id}?key=#{@api_key}" %>
                  <input
                    type="text"
                    value={link}
                    readonly
                    class="w-full border border-gray-300 rounded-md px-2 py-1 text-xs bg-gray-50 text-gray-700 hover:bg-white cursor-pointer"
                    onclick="this.select()"
                  />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <!-- нижняя панель -->
      <div class="text-sm text-gray-500 mt-6 text-center">
        Всего файлов: <%= length(@files) %>
      </div>
    </div>
    """
  end

  # ——— helpers ———
  defp authorize(nil), do: {:error, :no_key}

  defp authorize(key) do
    case Repo.get_by(ApiKey, key: key, active: true) do
      nil -> {:error, :invalid}
      api_key -> {:ok, api_key.owner, api_key.key, api_key.host}
    end
  end

  defp filter_files(files, ""), do: files

  defp filter_files(files, q) do
    q = String.downcase(q)

    Enum.filter(files, fn f ->
      String.contains?(String.downcase(f.filename), q) or
        String.contains?(String.downcase(f.description || ""), q)
    end)
  end

  defp apply_filter_sort(socket, files \\ nil) do
    files = files || socket.assigns.files
    filtered = filter_files(files, socket.assigns.filter)

    Enum.sort_by(
      filtered,
      &Map.get(&1, socket.assigns.sort_field),
      sort_direction(socket.assigns.sort_dir)
    )
  end

  defp sort_direction(:asc), do: &<=/2
  defp sort_direction(:desc), do: &>=/2

  defp current_page(files, page, size),
    do: files |> Enum.chunk_every(size) |> Enum.at(page - 1, [])

  defp total_pages(files, size), do: div(length(files) + size - 1, size)
  defp format_size(bytes) when bytes < 1_000_000, do: "#{div(bytes, 1000)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_000_000, 2)} MB"
end
