# ------------------- lib/storage_g/workers/demo_worker.ex -------------------
defmodule StorageG.Workers.DemoWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    IO.puts("[DemoWorker] Выполняю задачу: #{message}")
    :ok
  end
end
