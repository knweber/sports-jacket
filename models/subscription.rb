require 'active_record'
require 'active_record/base'
require_relative '../lib/recharge_api'
require_relative '../lib/async'
require_relative 'application'

class Subscription < ActiveRecord::Base
  include ApplicationRecord
  include Async
  include RechargeActiveRecordInclude

  self.primary_key = :subscription_id

  belongs_to :customer
  has_many :line_items, class_name: 'SubLineItem'
  has_many :order_line_items, class_name: 'OrderLineItemsFixed'
  has_many :orders, through: :order_line_items
  has_and_belongs_to_many :charges, join_table: 'charge_fixed_line_items'

  after_save :update_line_items

  # products that get shipped more than once per billing cycle
  PREPAID_PRODUCTS = [
    { id: '9421067602', title: '3 MONTHS' },
    { id: '9109818066', title: 'VIP 3 Month Box' },
    { id: '9175678162', title: 'VIP 3 Monthly Box' },
  ].freeze

  # for changing sizes
  CURRENT_PRODUCTS = [
    { id: '8204555081', title: 'Monthly Box' },
    { id: '9175678162', title: 'VIP 3 Monthly Box' },
    { id: '10870327954', title: 'Alternate Monthly Box/ Fit to Be Seen' },
    { id: '23729012754', title: 'NEW 3 MONTHS' },
    { id: '9109818066', title: 'VIP 3 Month Box' },
    { id: '10016265938', title: 'Ellie 3- Pack: ' },
    { id: '10870682450', title: 'Fit to Be Seen Ellie 3- Pack' },
    { id: '52386037778', title: 'Go Time - 3 Item' },
    { id: '44383469586', title: 'Go Time - 5 Item' },
    { id: '69026938898', title: 'Power Moves - 3 Item' },
    { id: '69026316306', title: 'Power Moves - 5 Item' },
  ].freeze

  # for skips/alternates
  SKIPPABLE_PRODUCTS = [
    { id: '8204555081', title: 'Monthly Box' },
    { id: '10016265938', title: 'Ellie 3- Pack: ' },
    { id: '69026938898', title: 'Power Moves - 3 Item' },
    { id: '69026316306', title: 'Power Moves - 5 Item' },
  ].freeze

  scope :skippable_products, -> { where shopify_product_id: SKIPPABLE_PRODUCTS.pluck(:id) }
  scope :current_products, -> { where shopify_product_id: CURRENT_PRODUCTS.pluck(:id), status: 'ACTIVE' }

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

  # skips the given subscription_id immeadiately
  # returns the updated active record object.
  def self.skip!(subscription_id)
    sub = Subscription.find(subscription_id)
    res = sub.skip
    return unless res[0]
    sub.recharge_update!
  end

  def prepaid?
    PREPAID_PRODUCTS.pluck(:id).include? shopify_product_id
  end

  def active?(time = nil)
    time ||= Time.current
    charges.where('scheduled_at > ?', time).count.positive? &&
      status == 'ACTIVE'
  end

  def skippable?
    skip_conditions = [
      !prepaid?,
      active?,
      Date.today.day < 5,
      SKIPPABLE_PRODUCTS.pluck(:id).include?(shopify_product_id),
      next_charge_scheduled_at.try('>', Date.today.beginning_of_month),
      next_charge_scheduled_at.try('<', Date.today.end_of_month),
    ]
    skip_conditions.all?
  end

  # returns a 2 element array. The first element indecateds if the subscription
  # can be successfully skipped. The second element is the unsaved active record
  # object with the new `next_charge_scheduled_at`
  def skip
    return false unless skippable?
    self.next_charge_scheduled_at += 1.month
    true
  end

  #def charges
    #Charge.by_subscription_id subscription_id
  #end

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

  def size_line_items
    line_items.where(name: SubLineItem::SIZE_PROPERTIES)
  end

  def sizes
    raw_line_item_properties
      .select{|p| SubLineItem::SIZE_PROPERTIES.include? p['name']}
      .map{|p| [p['name'], p['value']]}
      .to_h
  end

  def sizes=(new_sizes)
    prop_hash = raw_line_item_properties.map{|prop| [prop['name'], prop['value']]}.to_h
    merged_hash = prop_hash.merge new_sizes
    puts "merged_hash = #{merged_hash}"
    self[:raw_line_item_properties] = merged_hash.map{|k,v| {'name' => k, 'value' => v}}
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
