defmodule StorageG.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StorageGWeb.Telemetry,
      StorageG.Repo,
      {DNSCluster, query: Application.get_env(:storage_g, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: StorageG.PubSub},
      # Start a worker by calling: StorageG.Worker.start_link(arg)
      # {StorageG.Worker, arg},
      # Start to serve requests, typically the last entry
      StorageGWeb.Endpoint,
      {Oban, Application.fetch_env!(:storage_g, :oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StorageG.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StorageGWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
