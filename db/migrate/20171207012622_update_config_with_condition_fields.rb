class UpdateConfigWithConditionFields < ActiveRecord::Migration[5.1]
  def change
    add_column :config, :theme_id, :string
    add_column :config, :active_start, :timestamp
    add_column :config, :active_end, :timestamp
  end
end
