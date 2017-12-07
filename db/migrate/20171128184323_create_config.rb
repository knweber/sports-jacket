class CreateConfig < ActiveRecord::Migration[5.1]
  def self.up
    execute <<-SQL
      create table config (
        key varchar(100) primary key,
        val jsonb,
        created_at timestamp without time zone
          not null default CURRENT_TIMESTAMP,
        updated_at timestamp without time zone
          not null default CURRENT_TIMESTAMP
      );
    SQL
  end

  def self.down
    drop_table :config
  end
end
