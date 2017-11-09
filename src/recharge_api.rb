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

  def as_recharge
    raise "ERROR: #{self.class.name}#as_recharge is not defined. This method is required to send data compatible with the Recharge API"
  end

  def recharge_update
    self.class.recharge_update(as_recharge)
  end

  def recharge_create
    self.class.recharge_create(as_recharge)
  end

  def recharge_delete
    self.class.recharge_delete(as_recharge)
  end

  module ClassMethods

    def from_recharge(*_)
      raise "Error: #{name}::from_recharge is not defined."
    end

    def fetch(id)
      raise 'unimplemented'
    end

    def recharge_count(options)
      res = RechargeAPI.get("/#{name.tableize}/count", query: options)
      res.parsed_response[:count]
    end

    def recharge_list(options)
      res = RechargeAPI.get("/#{name.tableize}", query: options)
      res.parsed_response[name.tableize]
    end

    def recharge_read(id)
      res = RechargeAPI.get("/#{name.tableize}/#{id}")
      res.parsed_response[name.underscore]
    end

    def recharge_update(obj)
      res = RechargeAPI.put("/#{name.tableize}/#{obj[:id]}", body: obj.to_json)
      res.parsed_response[name.underscore]
    end

    def recharge_create(obj)
      res = RechargeAPI.post("/#{name.tableize}", body: obj.to_json)
      res.success?
    end

    def recharge_delete(id)
      res = RechargeAPI.delete("/#{name.tableize}/#{id}")
      res.success?
    end

    private

    def diff(left, right)
      column_names.reject { |col| left[col] == right[col] }
    end
  end
end
