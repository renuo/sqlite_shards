# SqliteShards

A gem to connect your ActiveRecord models to a separate sqlite file.

Some data does not belong into the app's main database. 
For example, on [onlylogs](https://github.com/renuo/onlylogs) we persist saved queries into a small sqlite file, 
without interfering with the main app database.

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
    ->(connection) { 
      connection.add_column(:notes, :body, :text) 
    }
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

Inside the block every model under `NotesRecord` reads and writes that file. 
Outside it, queries raise `ActiveRecord::ConnectionNotDefined`, so data can't end up in the wrong place by accident.

Wrapping it in the object that owns the file reads well:

```ruby
class Project < ApplicationRecord
  def with_database(create: true, &) = NotesRecord.with_database(root_path.join("notes.db"), create:, &)
end

project.with_database { Note.count }
```

### Without a block

`bound_to` returns a relation you can keep, chain and write through outside a block. 
Every call on it, and on the relations and records it returns, runs inside the database:

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

## Requirements

Active Record 8.0 or newer and the `sqlite3` gem. 

## Development

```sh
bin/setup
bin/check      # tests
bin/fastcheck  # standardrb
```

## License

MIT, see [LICENSE.txt](LICENSE.txt).
