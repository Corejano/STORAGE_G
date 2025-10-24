alias StorageG.{Repo, ApiKeys.ApiKey}

super_key = System.get_env("SUPER_ADMIN_KEY") || "SUPER_KEY"
super_owner = System.get_env("SUPER_ADMIN_OWNER") || "Admin"
super_host = System.get_env("SUPER_ADMIN_HOST") || "http://localhost:4000"

unless Repo.get_by(ApiKey, owner: super_owner) do
  Repo.insert!(%ApiKey{
    key: super_key,
    owner: super_owner,
    active: true,
    host: super_host,
    role: "super"
  })

  IO.puts("✅ Добавлен суперпользователь #{super_owner} (#{super_key})")
else
  IO.puts("ℹ️  Суперпользователь уже существует: #{super_owner}")
end
