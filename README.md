# SqliteShards

Active Record models whose data lives in SQLite files you pick at runtime, one database per file.

Some data belongs next to something on disk rather than in the app's main database: saved searches next to a log
directory, per-project statistics in the project's folder, metadata next to an upload. Keeping it in a SQLite file
there means it moves when the folder moves and is gone when the folder is deleted, with no foreign keys or cleanup
jobs, while the code still uses ordinary Active Record models.

## Usage

Include `SqliteShards` in an abstract class and list its migrations:

```ruby
class NotesRecord < ActiveRecord::Base
  self.abstract_class = true
  include SqliteShards

  database_migrations(
    ->(connection) {
      connection.create_table(:notes) do |t|
        t.string :title, null: false
        t.timestamps
      end
    },
    ->(connection) { connection.add_column(:notes, :body, :text) }
  )
end

class Note < NotesRecord
end
```

Then pick a file:

```ruby
NotesRecord.with_database("storage/projects/acme/notes.db") do
  Note.create!(title: "Hello")
  Note.where(title: "Hello").count
end
```

Inside the block every model under `NotesRecord` reads and writes that file. Outside it, queries raise
`ActiveRecord::ConnectionNotDefined`, so data can't end up in the wrong place by accident.

Wrapping it in the object that owns the file reads well:

```ruby
class Project < ApplicationRecord
  def with_database(create: true, &) = NotesRecord.with_database(root_path.join("notes.db"), create:, &)
end

project.with_database { Note.count }
```

### Without a block

`bound_to` returns a relation you can keep, chain and write through outside a block. Every call on it, and on the
relations and records it returns, runs inside the database:

```ruby
class Project < ApplicationRecord
  def notes = NotesRecord.bound_to(root_path.join("notes.db")) { Note.order(created_at: :desc) }
end

note = project.notes.create!(title: "Hello")
note.update!(title: "Hi")
project.notes.where(title: "Hi").pluck(:id)
```

The records it returns are wrappers that forward every call, so `note.class` is `SqliteShards::Bound`, not `Note`.

### Options

- `with_database(path, create: false)` yields nothing and returns `nil` when the file doesn't exist, instead of
  creating it. Useful for reading without leaving empty databases behind.
- `NotesRecord.transaction { ... }` inside `with_database` spans all models of that file: they share one connection.
- `with_database` calls nest, for the same class or different ones.
- `clear_database_connections` closes every connection the class opened.

## How it works

- **Each file is a shard** of the including class. It is connected the first time it is used, with
  `connected_to(shard:)`, so the choice of file is per thread and per fiber.
- **Migrations** are blocks run in order and tracked in SQLite's `PRAGMA user_version`. They run the first time a file
  is connected, inside an `IMMEDIATE` transaction, so two processes opening the same file can't run them twice. Append
  new ones; never edit or reorder migrations that have shipped.
- **The schema is known without a file.** Every file is migrated the same way, so when no file is connected Active
  Record reads columns, types and the primary key from an in-memory database migrated like the files. `Note.new`,
  form builders and controller parameter wrapping work anywhere; only queries need a file.
- **A file replaced on disk** (deleted and recreated, or a folder renamed and another one created under its name) has
  a different device and inode, so it gets a shard of its own. The old shard isn't torn down; its idle connections are
  closed by the pool reaper, so a connection in use, like a test's transaction, is never pulled away.

## Requirements

Active Record 8.0 or newer and the `sqlite3` gem. To know the schema without a file it hooks into three Active Record
class methods that read a model's schema (`schema_cache`, `load_schema`, `_default_attributes`); the test suite covers
that behaviour, so an Active Record upgrade that changes them shows up as a failing test.

## Development

```sh
bin/setup
bin/check      # tests
bin/fastcheck  # standardrb
```

## License

MIT, see [LICENSE.txt](LICENSE.txt).
