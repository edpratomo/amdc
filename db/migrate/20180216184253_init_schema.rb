class InitSchema < ActiveRecord::Migration[5.1]
  def change
    execute <<-SQL
CREATE TABLE matches (
  id SERIAL PRIMARY KEY,
  source_id TEXT NOT NULL UNIQUE, --- match id from chess.com
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE snapshots (
  id SERIAL PRIMARY KEY,
  match_id INTEGER REFERENCES matches(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL UNIQUE,
  raw TEXT NOT NULL,
  diff TEXT
);
SQL
  end
end
