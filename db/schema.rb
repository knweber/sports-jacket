# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171004183754) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "charge_billing_address", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "company"
    t.string "country"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "province"
    t.string "zip"
    t.string "charge_id"
    t.index ["charge_id"], name: "index_charge_billing_address_on_charge_id"
  end

  create_table "charge_client_details", force: :cascade do |t|
    t.string "charge_id"
    t.string "browser_ip"
    t.string "user_agent"
    t.index ["charge_id"], name: "index_charge_client_details_on_charge_id"
  end

  create_table "charge_fixed_line_items", force: :cascade do |t|
    t.string "charge_id"
    t.integer "grams"
    t.decimal "price", precision: 10, scale: 2
    t.integer "quantity"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.string "sku"
    t.string "subscription_id"
    t.string "title"
    t.string "variant_title"
    t.string "vendor"
    t.index ["charge_id"], name: "index_charge_fixed_line_items_on_charge_id"
  end

  create_table "charge_variable_line_items", force: :cascade do |t|
    t.string "charge_id"
    t.string "name"
    t.string "value"
    t.index ["charge_id"], name: "index_charge_variable_line_items_on_charge_id"
  end

  create_table "charges", force: :cascade do |t|
    t.string "address_id"
    t.jsonb "billing_address"
    t.jsonb "client_details"
    t.datetime "created_at"
    t.string "customer_hash"
    t.string "customer_id"
    t.string "first_name"
    t.string "charge_id"
    t.string "last_name"
    t.jsonb "line_items"
    t.string "note"
    t.jsonb "note_attributes"
    t.datetime "processed_at"
    t.datetime "scheduled_at"
    t.integer "shipments_count"
    t.jsonb "shipping_address"
    t.string "shopify_order_id"
    t.string "status"
    t.decimal "sub_total", precision: 10, scale: 2
    t.decimal "sub_total_price", precision: 10, scale: 2
    t.string "tags"
    t.decimal "tax_lines", precision: 10, scale: 2
    t.decimal "total_discounts", precision: 10, scale: 2
    t.decimal "total_line_items_price", precision: 10, scale: 2
    t.decimal "total_tax", precision: 10, scale: 2
    t.integer "total_weight"
    t.decimal "total_price", precision: 10, scale: 2
    t.datetime "updated_at"
    t.jsonb "discount_codes"
    t.index ["address_id"], name: "index_charges_on_address_id"
    t.index ["charge_id"], name: "index_charges_on_charge_id"
    t.index ["customer_id"], name: "index_charges_on_customer_id"
  end

  create_table "charges_shipping_address", force: :cascade do |t|
    t.string "charge_id"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "company"
    t.string "country"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "province"
    t.string "zip"
    t.index ["charge_id"], name: "index_charges_shipping_address_on_charge_id"
  end

  create_table "charges_shipping_lines", force: :cascade do |t|
    t.string "charge_id"
    t.string "code"
    t.decimal "price", precision: 10, scale: 2
    t.string "source"
    t.string "title"
    t.jsonb "tax_lines"
    t.string "carrier_identifier"
    t.string "request_fulfillment_service_id"
    t.index ["charge_id"], name: "index_charges_shipping_lines_on_charge_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "customer_id"
    t.string "hash"
    t.string "shopify_customer_id"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "last_name"
    t.string "billing_address1"
    t.string "billing_address2"
    t.string "billing_zip"
    t.string "billing_city"
    t.string "billing_company"
    t.string "billing_province"
    t.string "billing_country"
    t.string "billing_phone"
    t.string "processor_type"
    t.string "status"
    t.index ["customer_id"], name: "index_customers_on_customer_id"
    t.index ["shopify_customer_id"], name: "index_customers_on_shopify_customer_id"
  end

  create_table "order_billing_address", force: :cascade do |t|
    t.string "order_id"
    t.string "province"
    t.string "city"
    t.string "first_name"
    t.string "last_name"
    t.string "zip"
    t.string "country"
    t.string "address1"
    t.string "address2"
    t.string "company"
    t.string "phone"
    t.index ["order_id"], name: "index_order_billing_address_on_order_id"
  end

  create_table "order_line_items_fixed", force: :cascade do |t|
    t.string "order_id"
    t.string "shopify_variant_id"
    t.string "title"
    t.string "variant_title"
    t.string "subscription_id"
    t.integer "quantity"
    t.string "shopify_product_id"
    t.string "product_title"
    t.index ["order_id"], name: "index_order_line_items_fixed_on_order_id"
    t.index ["subscription_id"], name: "index_order_line_items_fixed_on_subscription_id"
  end

  create_table "order_line_items_variable", force: :cascade do |t|
    t.string "order_id"
    t.string "name"
    t.string "value"
    t.index ["order_id"], name: "index_order_line_items_variable_on_order_id"
  end

  create_table "order_shipping_address", force: :cascade do |t|
    t.string "order_id"
    t.string "province"
    t.string "city"
    t.string "first_name"
    t.string "last_name"
    t.string "zip"
    t.string "country"
    t.string "address1"
    t.string "address2"
    t.string "company"
    t.string "phone"
    t.index ["order_id"], name: "index_order_shipping_address_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_id"
    t.string "transaction_id"
    t.string "charge_status"
    t.string "payment_processor"
    t.integer "address_is_active"
    t.string "status"
    t.string "type"
    t.string "charge_id"
    t.string "address_id"
    t.string "shopify_id"
    t.string "shopify_order_id"
    t.string "shopify_order_number"
    t.string "shopify_cart_token"
    t.datetime "shipping_date"
    t.datetime "scheduled_at"
    t.datetime "shipped_date"
    t.datetime "processed_at"
    t.string "customer_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "is_prepaid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.jsonb "line_items"
    t.decimal "total_price", precision: 10, scale: 2
    t.jsonb "shipping_address"
    t.jsonb "billing_address"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["charge_id"], name: "index_orders_on_charge_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_id"], name: "index_orders_on_order_id"
    t.index ["shopify_id"], name: "index_orders_on_shopify_id"
    t.index ["shopify_order_id"], name: "index_orders_on_shopify_order_id"
    t.index ["shopify_order_number"], name: "index_orders_on_shopify_order_number"
    t.index ["transaction_id"], name: "index_orders_on_transaction_id"
  end

  create_table "sub_line_items", force: :cascade do |t|
    t.string "subscription_id"
    t.string "name"
    t.string "value"
    t.index ["subscription_id"], name: "index_sub_line_items_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "subscription_id"
    t.string "address_id"
    t.string "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "next_charge_scheduled_at"
    t.datetime "cancelled_at"
    t.string "product_title"
    t.decimal "price", precision: 10, scale: 2
    t.integer "quantity"
    t.string "status"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.string "sku"
    t.string "order_interval_unit"
    t.integer "order_interval_frequency"
    t.integer "charge_interval_frequency"
    t.integer "order_day_of_month"
    t.integer "order_day_of_week"
    t.jsonb "raw_line_item_properties"
    t.index ["address_id"], name: "index_subscriptions_on_address_id"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["subscription_id"], name: "index_subscriptions_on_subscription_id"
  end

  create_table "update_line_items", force: :cascade do |t|
    t.string "subscription_id"
    t.jsonb "properties"
    t.boolean "updated", default: false
  end

end
