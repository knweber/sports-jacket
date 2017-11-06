require 'httparty'
require_relative 'logging'

class RechargeAPI
  include HTTParty
  include Logging

  @@base_uri = "https://api.rechargeapps.com"
  @@sleep_time = ENV['RECHARGE_SLEEP_TIME']
  @@access_token = ENV['RECHARGE_ACCESS_TOKEN']
  @@default_headers = {
    'X-Recharge-Access-Token' => @@access_token,
    'Accept' => 'application/json',
    'Content-Type' => 'application/json',
  }

  attr_reader :access_token, :default_headers

  def self.get(route, options = {})
    options[:headers] ||= {
      "X-Recharge-Access-Token" => ENV['RECHARGE_ACCESS_HEADER'],
      "Accept" => "application/json",
    }
    HTTParty.get(@@base_uri + route, options)
  end

  def self.put(route, options = {})
    options[:headers] ||= {
      "X-Recharge-Access-Token" => ENV['RECHARGE_ACCESS_HEADER'],
      "Accept" => "application/json",
      "Content-Type" => "application/json",
    }
    HTTParty.put(route, options)
  end

  def self.subscriptions_by_shopify_id(shopify_id)
    customer = Customer.find_by(shopify_customer_id: shopify_id)
    return [] if customer.nil?
    res = HTTParty.get("#{@@base_uri}/subscriptions?customer_id=#{customer.customer_id}", headers: @@default_headers)
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
