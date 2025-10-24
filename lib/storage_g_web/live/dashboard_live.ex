defmodule StorageGWeb.DashboardLive do
  @moduledoc """
  LiveView-дашборд для просмотра и фильтрации загруженных файлов.
  Реальное обновление, сортировка, пагинация и ссылки для копирования.
  """

  use StorageGWeb, :live_view
  alias StorageG.{Repo, Files.File, ApiKeys.ApiKey}

  @topic "files:updates"
  @page_size 20

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

  # ——— handle_info: при добавлении нового файла ———
  @impl true
  def handle_info({:new_file, file}, socket) do
    files = [file | socket.assigns.files]

    {:noreply,
     socket
     |> assign(:files, files)
     |> assign(:filtered, apply_filter_sort_paginate(socket, files))}
  end

  # ——— handle_event: фильтр ———
  @impl true
  def handle_event("filter", %{"q" => q}, socket) do
    {:noreply,
     socket
     |> assign(:filter, q)
     |> assign(:page, 1)
     |> assign(:filtered, apply_filter_sort_paginate(socket))}
  end

  # ——— handle_event: сортировка ———
  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)

    dir =
      if socket.assigns.sort_field == field_atom and socket.assigns.sort_dir == :asc do
        :desc
      else
        :asc
      end

    {:noreply,
     socket
     |> assign(:sort_field, field_atom)
     |> assign(:sort_dir, dir)
     |> assign(:filtered, apply_filter_sort_paginate(socket))}
  end

  # ——— handle_event: пагинация ———
  @impl true
  def handle_event("page", %{"to" => dir}, socket) do
    new_page =
      case dir do
        "prev" ->
          max(socket.assigns.page - 1, 1)

        "next" ->
          if socket.assigns.page * @page_size < length(socket.assigns.filtered) do
            socket.assigns.page + 1
          else
            socket.assigns.page
          end
      end

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> assign(:filtered, apply_filter_sort_paginate(socket))}
  end

  # ——— render ———
  @impl true
  def render(assigns) do
    ~H"""
    <div id="dashboard" class="p-6 max-w-7xl mx-auto bg-gradient-to-b from-gray-50 to-white rounded-xl shadow-xl">
      <h1 class="text-3xl font-bold mb-6 text-gray-800">📂 Storage Dashboard</h1>

      <div class="mb-4 text-gray-700">
        Привет, <b><%= @owner %></b>! Ваш ключ:
        <code class="bg-gray-100 p-1 rounded"><%= @api_key %></code>
      </div>

      <div class="mb-3 text-sm text-gray-500">
        Нажмите на поле ссылки и используйте <b>Ctrl+C</b> для копирования.
      </div>

      <div class="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <input
          type="text"
          name="q"
          value={@filter}
          phx-change="filter"
          placeholder="🔍 Поиск по имени или описанию..."
          class="border rounded px-3 py-2 w-full sm:w-96 shadow-sm focus:ring focus:ring-blue-200"
        />

        <div class="flex gap-2">
          <button phx-click="page" phx-value-to="prev"
            class="px-3 py-1 border rounded bg-white hover:bg-gray-100 text-sm">← Назад</button>
          <button phx-click="page" phx-value-to="next"
            class="px-3 py-1 border rounded bg-white hover:bg-gray-100 text-sm">Вперёд →</button>
        </div>
      </div>

      <div class="overflow-x-auto border border-gray-200 rounded-lg shadow">
        <table class="min-w-full text-sm text-left">
          <thead class="bg-blue-100 border-b border-gray-300 text-gray-700">
            <tr>
              <th class="p-3 cursor-pointer" phx-click="sort" phx-value-field="filename">Имя</th>
              <th class="p-3">Описание</th>
              <th class="p-3 cursor-pointer" phx-click="sort" phx-value-field="size">Размер</th>
              <th class="p-3">Тип</th>
              <th class="p-3 cursor-pointer" phx-click="sort" phx-value-field="inserted_at">Дата</th>
              <th class="p-3">Хэш</th>
              <th class="p-3">Ссылка</th>
            </tr>
          </thead>

          <tbody>
            <%= for f <- current_page(@filtered, @page, @page_size) do %>
              <tr class="hover:bg-gray-50 border-t align-top">
                <td class="p-3 font-medium text-gray-800"><%= f.filename %></td>
                <td class="p-3 text-gray-600 max-w-[18rem] break-words">
                  <%= if (f.description || "") == "" do %>
                    <span class="italic text-gray-400">—</span>
                  <% else %>
                    <%= f.description %>
                  <% end %>
                </td>
                <td class="p-3 text-gray-600 whitespace-nowrap"><%= format_size(f.size) %></td>
                <td class="p-3 text-gray-600 whitespace-nowrap"><%= f.mime_type %></td>
                <td class="p-3 text-gray-600 whitespace-nowrap"><%= f.inserted_at %></td>
                <td class="p-3 text-xs text-gray-500 break-all">
                  <%= if f.hash do %>
                    <%= String.slice(f.hash, 0, 12) %>...
                  <% else %>
                    <span class="italic text-gray-400">pending</span>
                  <% end %>
                </td>
                <td class="p-3">
                  <% link = "#{@host}/api/file/#{f.id}?key=#{@api_key}" %>
                  <input
                    type="text"
                    value={link}
                    readonly
                    class="w-[22rem] border rounded px-2 py-1 bg-gray-50 text-gray-800 text-xs"
                    onclick="this.select()"
                  />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <div class="text-center text-sm text-gray-500 mt-3">
        Страница <%= @page %> из <%= total_pages(@filtered, @page_size) %>
      </div>
    </div>
    """
  end

  # ——— Helpers ———

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

  # применяет фильтр, сортировку и пагинацию
  defp apply_filter_sort_paginate(socket, files \\ nil) do
    files = files || socket.assigns.files
    filtered = filter_files(files, socket.assigns.filter)
    sorted = sort_files(filtered, socket.assigns.sort_field, socket.assigns.sort_dir)
    sorted
  end

  defp sort_files(files, field, dir) do
    Enum.sort_by(files, &Map.get(&1, field), sort_direction(dir))
  end

  defp sort_direction(:asc), do: &<=/2
  defp sort_direction(:desc), do: &>=/2

  defp current_page(files, page, size) do
    files |> Enum.chunk_every(size) |> Enum.at(page - 1, [])
  end

  defp total_pages(files, size) do
    div(length(files) + size - 1, size)
  end

  defp format_size(bytes) when bytes < 1_000_000, do: "#{div(bytes, 1000)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_000_000, 2)} MB"
end
