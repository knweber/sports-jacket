require 'active_record'
require 'active_record/base'
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

  after_save :update_line_items

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
    to_f = ->(x) { x.to_f }
    [
      {
        remote_key: 'id',
        local_key: 'subscription_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'address_id',
        local_key: 'address_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'customer_id',
        local_key: 'customer_id',
        inbound: identity,
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
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'shopify_variant_id',
        local_key: 'shopify_variant_id',
        inbound: identity,
        outbound: to_i,
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

  # skips the given subscription_id
  def self.skip!(subscription_id)
    charges = Charge.by_subscription_id subscription_id
    results = charges.each do |charge|
      res = RechargeAPI.skip!(charge.charge_id, subscription_id)
      Subscription.recharge_read subscription_id if res.success?
      charge.update(Charge.from_recharge(res.parsed_body['charge']))
      res.success?
    end
    results.all?
  end

  def initialize(*_args)
    @sync_recharge = false
  end

  def prepaid?
    PREPAID_PRODUCTS.pluck(:id).include? shopify_product_id
  end

  def skip!
    Subscription.skip! subscription_id
  end

  def charges
    Charge.by_subscription_id subscription_id
  end

  def next_charge(time = nil)
    time ||= Time.current
    charges.where('scheduled_at > ?', time)
      .order(scheduled_at: :asc)
      .first
  end

  def shipping_at
    next_order = orders.where(status: 'QUEUED')
                       .where('scheduled_at > ?', Date.today)
                       .order(:scheduled_at)
                       .first
    next_order.try(&:scheduled_at)
  end

  def sizes
    line_items.where(name: SubLineItem::SIZE_PROPERTIES)
  end

  private

  def update_line_items
    return unless saved_change_to_attribute? :raw_line_item_properties
    Subscription.transaction do
      raw_line_item_properties.each do |prop|
        sub = SubLineItem.find_or_create_by(
          subscription_id: subscription_id,
          name: prop[:name],
        )
        sub.value = prop[:value]
        sub.save!
      end
    end
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

  after_save :update_shipping_address_assoc
  after_save :update_shipping_lines

  def self.api_map
    # helper functions
    identity = ->(x) { x }
    to_s = ->(x) { x.to_s }
    to_i = ->(x) { x.to_i }
    recharge_time = ->(time) { time.try(:strftime, '%FT%T') }
    to_time = ->(str) { str.nil? ? nil : Time.parse(str) }
    to_f = ->(x) { x.to_f }
    [
      {
        remote_key: 'id',
        local_key: 'charge_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'address_id',
        local_key: 'address_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'billing_address',
        local_key: 'billing_address',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'browser_ip',
        local_key: 'browser_ip',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'client_details',
        local_key: 'client_details',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'created_at',
        local_key: 'created_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'customer_hash',
        local_key: 'customer_hash',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'customer_id',
        local_key: 'customer_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'first_name',
        local_key: 'first_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'last_name',
        local_key: 'last_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'line_items',
        local_key: 'line_items',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'line_items',
        local_key: 'raw_line_items',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'note',
        local_key: 'note',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'note_attributes',
        local_key: 'note_attributes',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'processed_at',
        local_key: 'processed_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'scheduled_at',
        local_key: 'scheduled_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'shipments_count',
        local_key: 'shipments_count',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shipping_address',
        local_key: 'shipping_address',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_order_id',
        local_key: 'shopify_order_id',
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
        remote_key: 'sub_total',
        local_key: 'sub_total',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'sub_total_price',
        local_key: 'sub_total_price',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'tags',
        local_key: 'tags',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'tax_lines',
        local_key: 'tax_lines',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_discounts',
        local_key: 'total_discounts',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_line_items_price',
        local_key: 'total_line_items_price',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_tax',
        local_key: 'total_tax',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_weight',
        local_key: 'total_weight',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_price',
        local_key: 'total_price',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'updated_at',
        local_key: 'updated_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'discount_codes',
        local_key: 'discount_codes',
        inbound: identity,
        outbound: identity,
      },
    ].freeze
  end

  def self.by_subscription_id(subscription_id)
    where("line_items @> \'[{\"subscription_id\": #{subscription_id.to_i}}]\'")
  end


  def line_items=(val)
    #logger.debug @attributes
    super(val)
  end

  private

  def update_shipping_address_assoc
  end

  def update_shipping_lines
    return unless raw_shipping_lines_changed?
    raw_shipping_lines
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

  has_one :line_items_fixed, class_name: 'OrderLineItemsFixed'
  has_one :line_items_variable, class_name: 'OrderLineItemsVariable'
  has_one :subscription, through: :line_items

  def self.api_map
    # helper functions
    identity = ->(x) { x }
    to_s = ->(x) { x.to_s }
    to_i = ->(x) { x.to_i }
    recharge_time = ->(time) { time.try(:strftime, '%FT%T') }
    to_time = ->(str) { str.nil? ? nil : Time.parse(str) }
    to_f = ->(x) { x.to_f }
    [
      {
        remote_key: 'id',
        local_key: 'order_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'address_id',
        local_key: 'address_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'address_is_active',
        local_key: 'address_is_active',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_address',
        local_key: 'billing_address',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'charge_id',
        local_key: 'charge_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'charge_status',
        local_key: 'charge_status',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'created_at',
        local_key: 'created_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'customer_id',
        local_key: 'customer_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'email',
        local_key: 'email',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'first_name',
        local_key: 'first_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'last_name',
        local_key: 'last_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'is_prepaid',
        local_key: 'is_prepaid',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'line_items',
        local_key: 'line_items',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'payment_processor',
        local_key: 'payment_processor',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'processed_at',
        local_key: 'processed_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'scheduled_at',
        local_key: 'scheduled_at',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'shipped_date',
        local_key: 'shipped_date',
        inbound: to_time,
        outbound: recharge_time,
      },
      {
        remote_key: 'shopify_cart_token',
        local_key: 'shopify_cart_token',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_id',
        local_key: 'shopify_id',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_order_id',
        local_key: 'shopify_order_id',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_order_number',
        local_key: 'shopify_order_number',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'status',
        local_key: 'status',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'total_price',
        local_key: 'total_price',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'transaction_id',
        local_key: 'transaction_id',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'type',
        local_key: 'order_type',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'updated_at',
        local_key: 'updated_at',
        inbound: to_time,
        outbound: recharge_time,
      },
    ]
  end

  def subscription_id
    line_items.subscription_id
  end
  
end

class Customer < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude

  self.primary_key = :customer_id

  has_many :subscriptions
  has_many :orders, through: :subscriptions

  def self.from_recharge(attributes, *args)
    key_map = { 'hash' => 'customer_hash' }
    remapped = attributes.map { |k, v| [key_map[k] || k, v] }.to_h
    logger.debug remapped
    Customer.new(remapped, *args)
  end

  def self.api_map
    # helper functions
    identity = ->(x) { x }
    to_s = ->(x) { x.to_s }
    to_i = ->(x) { x.to_i }
    recharge_time = ->(time) { time.try(:strftime, '%FT%T') }
    to_time = ->(str) { str.nil? ? nil : Time.parse(str) }
    to_f = ->(x) { x.to_f }
    [
      {
        remote_key: 'id',
        local_key: 'customer_id',
        inbound: identity,
        outbound: to_i,
      },
      {
        remote_key: 'hash',
        local_key: 'customer_hash',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'shopify_customer_id',
        local_key: 'shopify_customer_id',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'email',
        local_key: 'email',
        inbound: identity,
        outbound: identity,
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
        remote_key: 'first_name',
        local_key: 'first_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'last_name',
        local_key: 'last_name',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_address1',
        local_key: 'billing_address1',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_address2',
        local_key: 'billing_address2',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_zip',
        local_key: 'billing_zip',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_city',
        local_key: 'billing_city',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_company',
        local_key: 'billing_company',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_province',
        local_key: 'billing_province',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_country',
        local_key: 'billing_country',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'billing_phone',
        local_key: 'billing_phone',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'processor_type',
        local_key: 'processor_type',
        inbound: identity,
        outbound: identity,
      },
      {
        remote_key: 'status',
        local_key: 'status',
        inbound: identity,
        outbound: identity,
      },
    ]
  end

  def _as_recharge
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
