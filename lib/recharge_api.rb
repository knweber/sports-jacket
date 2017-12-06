require 'httparty'
require 'active_support'
require 'active_support/core_ext'
require_relative 'logging'

class RechargeAPI
  include HTTParty
  include Logging

  BASE_URI = 'https://api.rechargeapps.com'.freeze
  @@sleep_time = ENV['RECHARGE_SLEEP_TIME']
  @@access_token = ENV['RECHARGE_ACCESS_TOKEN']
  @@default_headers = {
    'X-Recharge-Access-Token' => @@access_token,
    'Accept' => 'application/json',
    'Content-Type' => 'application/json'
  }

  attr_reader :access_token, :default_headers

  def self.get(route, options = {})
    options[:headers] ||= {
      'X-Recharge-Access-Token' => @@access_token,
      'Accept' => 'application/json'
    }
    HTTParty.get(BASE_URI + route, options)
  end

  def self.put(route, options = {})
    options[:headers] ||= @@default_headers
    HTTParty.put(BASE_URI + route, options)
  end

  def self.post(route, options = {})
    options[:headers] ||= @@default_headers
    HTTParty.post(BASE_URI + route, options)
  end

  def self.subscriptions_by_shopify_id(shopify_id)
    customer = Customer.find_by(shopify_customer_id: shopify_id)
    return [] if customer.nil?
    res = HTTParty.get("#{BASE_URI}/subscriptions?customer_id=#{customer.customer_id}", headers: @@default_headers)
    if res.ok?
      logger.debug 'response was ok!'
      res.parsed_response['subscriptions']
    else
      logger.debug 'response was NOT ok!'
      logger.debug res.request.uri
      logger.debug res.code
      logger.debug default_headers
      logger.debug res.body
      []
    end
  end

end

module RechargeActiveRecordInclude
  def self.included(base)
    base.extend(ClassMethods)
  end

  def recharge_update!
    self.class.recharge_update(as_recharge)
  end

  def recharge_create!
    self.class.recharge_create(as_recharge)
  end

  def recharge_delete!
    self.class.recharge_delete(as_recharge)
  end

  def as_recharge
    remapped = self.class.api_map.map do |m|
      local = self[m[:local_key]]
      transform = m[:outbound] || ->(i){ i }
      [m[:remote_key], transform.call(local)]
    end
    remapped.to_h
  end

  def from_recharge(obj)

  end

  module ClassMethods

    def from_recharge(obj)
      #raise "Error: #{name}::from_recharge is not defined."
      new(map_in(obj))
    end

    def recharge_count(query, _options = {})
      res = RechargeAPI.get("/#{name.tableize}/count", query: query)
      res.parsed_response[:count]
    end

    def recharge_list(query, _options = {})
      res = RechargeAPI.get("/#{name.tableize}", query: query)
      res.parsed_response[name.tableize]
    end

    def recharge_read(id, given_options = {})
      default_options = { persist: true }
      options = default_options.merge given_options
      res = RechargeAPI.get("/#{name.tableize}/#{id}")
      return unless res.success?
      parsed = res.parsed_response[name.underscore]
      mapped = map_in(parsed)
      existing_record = find(id)
      logger.debug "parsed: #{parsed}"
      logger.debug "mapped in: #{mapped}"
      return new(mapped) unless options[:persist]
      if existing_record.nil?
        create mapped
      else
        existing_record.update mapped
        existing_record
      end
    end

    def recharge_update(obj, given_options = {})
      default_options = { persist: true }
      options = default_options.merge given_options
      res = RechargeAPI.put("/#{name.tableize}/#{obj[:id]}", body: obj.to_json)
      return unless res.success? && options[:persist]
      parsed = res.parsed_response[name.underscore]
      logger.debug "Recharge sent: #{res.inspect}"
      puts "Recharge sent: #{res.inspect}"
      find(parsed[:id]).update(map_in(obj))
    end

    def recharge_create(obj, given_options = {})
      default_options = { persist: true }
      options = default_options.merge given_options
      res = RechargeAPI.post("/#{name.tableize}", body: obj.to_json)
      return unless res.success? && options[:persist]
      parsed = res.parsed_response[name.underscore]
      create(map_in(parsed)) 
    end

    def recharge_delete(id, given_options = {})
      default_options = { persist: true }
      options = default_options.merge given_options
      res = RechargeAPI.delete("/#{name.tableize}/#{id}")
      return unless res.success? && options[:persist]
      delete id
    end

    def map_in(obj)
      remapped = api_map.map do |m|
        remote = obj[m[:remote_key]]
        transform = m[:inbound]
        [m[:local_key], transform.call(remote)]
      end
      remapped.to_h
    end
    
    private

    def diff(left, right)
      column_names.reject { |col| left[col] == right[col] }
    end
  end
end
