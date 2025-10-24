# dedup_keys.exs
import Ecto.Query
alias StorageG.Repo
alias StorageG.ApiKeys.ApiKey

# ищем владельцев с дубликатами
Repo.all(
  from a in ApiKey,
    group_by: a.owner,
    having: count(a.id) > 1,
    select: {a.owner, count(a.id)}
)
|> Enum.each(fn {owner, count} ->
  IO.puts("⚠️  Найдено #{count} ключей для владельца: #{owner}. Удаляем дубликаты...")

  # оставляем один, остальные удаляем
  Repo.delete_all(
    from a in ApiKey,
      where:
        a.owner == ^owner and
          a.id not in subquery(
            from x in ApiKey,
              where: x.owner == ^owner,
              limit: 1,
              select: x.id
          )
  )
end)

IO.puts("✅ Проверка завершена. Все владельцы теперь уникальны.")
