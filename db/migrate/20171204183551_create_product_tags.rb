class CreateProductTags < ActiveRecord::Migration[5.1]
  def change
    create_table :product_tags do |t|
      t.string :product_id, null: false
      t.string :tag, null: false
      t.timestamp :active_start
      t.timestamp :active_end
      t.string :theme_id
    end
  end
end
