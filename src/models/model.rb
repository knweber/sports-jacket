require 'active_record'
require 'active_record/base'
require 'safe_attributes'
require_relative '../recharge_api'
require_relative '../async'

module ApplicationRecord
end

class Subscription < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude

  self.primary_key = :subscription_id

  belongs_to :customer
  has_many :line_items, class_name: 'SubLineItem'
  has_many :order_line_items, class_name: 'OrderLineItemsFixed'
  has_many :orders, through: :order_line_items
                    #foreign_key: :subscription_id,

  PREPAID_PRODUCTS = [
    { id: '9421067602', title: '3 MONTHS' },
    { id: '8204584905', title: '6 Month Box' },
    { id: '9109818066', title: 'VIP 3 Month Box' },
    { id: '9175678162', title: 'VIP 3 Monthly Box' }
  ].freeze

  CURRENT_PRODUCTS = [
    { id: '8204555081', title: 'Monthly Box' },
    { id: '9175678162', title: 'VIP 3 Monthly Box' },
    { id: '10870327954', title: 'Alternate Monthly Box/ Fit to Be Seen' },
    { id: '23729012754', title: 'NEW 3 MONTHS' },
    { id: '9109818066', title: 'VIP 3 Month Box' },
    { id: '10016265938', title: 'Ellie 3- Pack: ' },
    { id: '10870682450', title: 'Fit to Be Seen Ellie 3- Pack' },
    { id: '8204555081', title: 'Monthly Box  Auto renew' }
  ].freeze

  # Defines the relationship between the local database table and the remote
  # Recharge data format
  def self.api_map
    # helper functions
    identity = ->(x) { x }
    to_s = ->(x) { x.to_s }
    to_i = ->(x) { x.to_i }
    recharge_time = ->(time) { time.try(:strftime, '%FT%T') }
    to_time = ->(str) { str.nil? ? nil : Time.parse(str) }
    [
      {
        remote_key: 'id',
        local_key: 'subscription_id',
        inbound: to_s,
        outbound: to_i,
      },
      {
        remote_key: 'address_id',
        local_key: 'address_id',
        inbound: to_s,
        outbound: to_i,
      },
      {
        remote_key: 'customer_id',
        local_key: 'customer_id',
        inbound: to_s,
        outbound: to_i,
      },
      {
        remote_key: 'created_at',
        local_key: 'created_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'updated_at',
        local_key: 'updated_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'next_charge_scheduled_at',
        local_key: 'next_charge_scheduled_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'cancelled_at',
        local_key: 'cancelled_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'product_title',
        local_key: 'product_title',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'price',
        local_key: 'price',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'quantity',
        local_key: 'quantity',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'status',
        local_key: 'status',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_product_id',
        local_key: 'shopify_product_id',
        inbound: ->(int){ int.to_s },
        outbound: ->(str){ str.to_i },
      },
      {
        remote_key: 'shopify_variant_id',
        local_key: 'shopify_variant_id',
        inbound: ->(int){ int.to_s },
        outbound: ->(str){ str.to_i },
      },
      {
        remote_key: 'sku',
        local_key: 'sku',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'order_interval_unit',
        local_key: 'order_interval_unit',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'order_interval_frequency',
        local_key: 'order_interval_frequency',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'order_day_of_month',
        local_key: 'order_day_of_month',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'order_day_of_week',
        local_key: 'order_day_of_week',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'properties',
        local_key: 'raw_line_item_properties',
        inbound: lambda do |p|
          logger.debug "parsing properties: #{p}"
          p || []
        end,
        outbound: identity,
      },
    ].freeze
  end

  attr_accessor :sync_recharge

  def initialize(*_args)
    @sync_recharge = false
  end

  def prepaid?
    PREPAID_PRODUCTS.pluck(:id).include? shopify_product_id
  end

  def shipping_at
    next_order = orders.where(status: 'QUEUED')
                       .where('scheduled_at > ?', Date.today)
                       .order(:scheduled_at)
                       .first
    next_order.try(&:scheduled_at)
  end
end

class SubLineItem < ActiveRecord::Base
  include ApplicationRecord

  self.primary_key = :subscription_id

  belongs_to :subscription

  SIZE_PROPERTIES = ['leggings', 'tops', 'sports-jacket', 'sports-bra'].freeze
  SIZE_VALUES = %w[XS S M L XL].freeze

  validate do |sub_item|
    if SIZE_PROPERTIES.include?(sub_item.name) && !SIZE_VALUES.include?(sub_item.value)
      sub_items.errors[:value] << 'Invalid size'
    end
  end

  before_save :sync_subscription

  def size_property?
    SIZE_PROPERTIES.include? name
  end

  private

  def sync_subscription
    sub = subscription
    sub.raw_line_item_properties.map! do |orig|
      orig[:name] == name ? { name: name, value: value } : orig
    end
    sub.save!
  end
end

class UpdateLineItem < ActiveRecord::Base
  include ApplicationRecord
end

class Charge < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude

  self.primary_key = :charge_id

  has_one :shipping_address_assoc, class_name: 'ChargeShippingAddress'
  has_many :shipping_lines, class_name: 'ChargeShippingLine'

  def as_recharge
    {
      address_id: address_id.to_i,
      billing_address: billing_address,
      client_details:  charge_details,
      created_at: created_at.try(:strftime, '%FT%T'),
      customer_hash: customer_hash,
      customer_id: customer_id.to_i,
      first_name: first_name,
      id: charge_id.to_i,
      last_name: last_name,
      line_items: line_items,
      processed_at: processed_at.try(:strftime, '%FT%T'),
      scheduled_at: scheduled_at.try(:strftime, '%FT%T'),
      shipments_count: shipments_count,
      shipping_address: shipping_address,
      shopify_order_id: shopify_order_id,
      status: status,
      total_price: total_price.to_s,
      updated_at: updated_at.try(:strftime, '%FT%T')
    }
  end
end

class ChargeShippingAddress < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'charges_shipping_address'
  belongs_to :charge
end

class ChargeShippingLine < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'charges_shipping_lines'
  belongs_to :charge
end

class OrderLineItemsFixed < ActiveRecord::Base
  include ApplicationRecord
  self.table_name = 'order_line_items_fixed'
  belongs_to :subscription
  belongs_to :order
end

class Order < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude
  # The column 'type' uses a reserved word in active record. Calling this class
  # results in:
  #
  # ActiveRecord::SubclassNotFound: The single-table inheritance mechanism
  # failed to locate the subclass: 'CHECKOUT'. This error is raised because the
  # column 'type' is reserved for storing the class in case of inheritance.
  # Please rename this column if you didn't intend it to be used for storing the
  # inheritance class or overwrite Order.inheritance_column to use another
  # column for that information.
  #
  # See: https://stackoverflow.com/questions/17879024/activerecordsubclassnotfound-the-single-table-inheritance-mechanism-failed-to
  self.inheritance_column = nil
  self.primary_key = :order_id

  has_one :line_items, class_name: 'OrderLineItemsFixed'
  has_one :subscription, through: :line_items

  def subscription_id
    line_items.subscription_id
  end

  def as_recharge
    {
      id: order_id.to_i,
      customer_id: customer_id.to_i,
      address_id: address_id.to_i,
      charge_id: charge_id.to_i,
      transaction_id: transaction_id,
      shopify_order_id: shopify_order_id,
      shopify_order_number: shopify_order_number.to_i,
      created_at: created_at.try(:strftime, '%FT%T'),
      updated_at: updated_at.try(:strftime, '%FT%T'),
      scheduled_at: scheduled_at.try(:strftime, '%FT%T'),
      processed_at: processed_at.try(:strftime, '%FT%T'),
      status: status,
      charge_status: charge_status,
      type: type,
      first_name: first_name,
      last_name: last_name,
      email: email,
      payment_processor: payment_processor,
      address_is_active: address_is_active,
      is_prepaid: is_prepaid,
      line_items: line_items,
      total_price: total_price.to_s,
      shipping_address: shipping_address,
      billing_address: billing_address
    }
  end
end

class Customer < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude

  self.primary_key = :customer_id

  has_many :subscriptions
  has_many :orders, through: :subscriptions

  # This safe attributes line is due to an actvive record error on the Customer
  # table. The table contains a column named `hash` which collides with the
  # ActiveRecord::Base#hash method. For mor info see:
  # https://github.com/rails/rails/issues/18338
  include SafeAttributes::Base

  def self.from_recharge(attributes, *args)
    key_map = { 'hash' => 'customer_hash' }
    remapped = attributes.map { |k, v| [key_map[k] || k, v] }.to_h
    logger.debug remapped
    Customer.new(remapped, *args)
  end

  def as_recharge
    {
      id: customer_id.to_i,
      hash: customer_hash,
      email: email,
      shopify_customer_id: shopify_customer_id,
      created_at: created_at.try(:strftime, '%FT%T'),
      updated_at: created_at.try(:strftime, '%FT%T'),
      first_name: first_name,
      last_name: last_name,
      billing_first_name: first_name,
      billing_last_name: last_name,
      billing_company: billing_company,
      billing_address1: billing_address1,
      billing_address2: billing_address2,
      billing_zip: billing_zip,
      billing_city: billing_city,
      billing_province: billing_province,
      billing_country: billing_country,
      billing_phone: billing_phone,
      processor_type: processor_type
    }
  end
end
