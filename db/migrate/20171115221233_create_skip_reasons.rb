class CreateSkipReasons < ActiveRecord::Migration[5.1]
  def change
    create_table(:skip_reasons, primary_key: :id) do |t|
      t.string :customer_id, null: false
      t.string :shopify_customer_id, null: false
      t.string :subscription_id, null: false
      t.string :charge_id
      t.string :reason
      t.timestamp :skipped_to
      t.boolean :skip_status
      t.timestamps
    end
    add_index :skip_reasons, :customer_id
    add_index :skip_reasons, :shopify_customer_id
    add_index :skip_reasons, :subscription_id
    add_index :skip_reasons, :charge_id
  end
end
