# Aegis Draft

Rails-приложение для составления драфтов в Dota 2 и ранжирования лучших
доступных героев с понятными рекомендациями, основанными на статистике.

## Требования

- Ruby 4.0.7
- Rails 8.1.4
- PostgreSQL 18+

## Локальный запуск

```sh
bin/setup
bin/rails server
```

## Проверки

```sh
bin/rails test
bundle exec rubocop --cache false
bundle exec brakeman --quiet --no-pager
```
