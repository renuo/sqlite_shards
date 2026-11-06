# Changelog

## 0.2.0

- At most `max_open_databases` files (100 by default) stay connected: connecting one more closes every file no thread
  is using. Before, every file kept its connection pool, file descriptors and page cache for the life of the process.
- A file whose migration fails no longer leaves its connection pool behind.

## 0.1.0

- First version, extracted from the onlylogs gem, where it keeps saved searches next to each log directory:
  `include SqliteShards`, `database_migrations`, `with_database(path) { ... }`, `bound_to(path) { scope }` and
  `clear_database_connections`.
