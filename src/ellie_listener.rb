require 'dotenv'
Dotenv.load
require 'sinatra/base'
require 'json'
require 'httparty'
require 'resque'
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'

#Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
require_relative 'models/model'
require_relative 'recharge_api'
require_relative 'logging'
require_relative 'resque_helper'

class HandlerError < StandardError
  DEFAULT_HEADERS = {}
  attr_accessor :headers, :status

  def initialize(msg, options)
    @status = options[:status] ? options[:status] : 500
    @headers = options[:headers] ? options[:headers] : DEFAULT_HEADERS
    
    super(msg)
  end

  def response
    [status, headers, message]
  end
end

class EllieListener < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  include Logging

  PAGE_LIMIT = 250

  configure do

    enable :logging
    set :server, :puma
    #set :protection, :except => [:json_csrf]

    mime_type :application_javascript, 'application/javascript'
    mime_type :application_json, 'application/json'
  end

  def initialize
    @tokens = {}
    @key = ENV['SHOPIFY_API_KEY']
    @secret = ENV['SHOPIFY_SHARED_SECRET']
    @app_url = 'ellieactivesupport.com'
    @default_headers = { 'Content-Type' => 'application/json' }
    @recharge_token = ENV['RECHARGE_ACCESS_TOKEN']
    @recharge_change_header = {
      "X-Recharge-Access-Token" => @recharge_token,
      "Accept" => "application/json",
      "Content-Type" =>"application/json"
    }

    super
  end

  get '/install' do
    shop = 'elliestaging.myshopify.com'
    scopes = 'read_orders, write_orders, read_products, read_customers, write_customers'

    # construct the installation URL and redirect the merchant
    install_url =
      "http://#{shop}/admin/oauth/authorize?client_id=#{@key}&scope=#{scopes}"\
      "&redirect_uri=http://#{@app_url}/auth/shopify/callback"

    redirect install_url
  end


  get '/auth/shopify/callback' do
    # extract shop data from request parameters
    shop = request.params['shop']
    code = request.params['code']
    hmac = request.params['hmac']

    # perform hmac validation to determine if the request is coming from Shopify
    h = request.params.reject{|k,_| k == 'hmac' || k == 'signature'}
    query = URI.escape(h.sort.collect{|k,v| "#{k}=#{v}"}.join('&'))
    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, query)

    unless hmac == digest
      return [403, "Authentication failed. Digest provided was: #{digest}"]
    end

    # if we don't have an access token for this particular shop,
    # we'll post the OAuth request and receive the token in the response
    if @tokens[shop].nil?
      url = "https://#{shop}/admin/oauth/access_token"

      payload = {
        client_id: @key,
        client_secret: @secret,
        code: code
      }

      response = HTTParty.post(url, body: payload)

      # if the response is successful, obtain the token and store it in a hash
      if response.code == 200
        @tokens[shop] = response['access_token']
      else
        return [500, 'Something went wrong.']
      end
    end

    # now that we have the token, we can instantiate a session
    session = ShopifyAPI::Session.new(shop, @tokens[shop])
    @my_session = session
    ShopifyAPI::Base.activate_session(session)

    # create webhook for order creation if it doesn't exist



    redirect '/hello'

  end

  get '/hello' do
    'Hello, success, thanks for installing me!'
  end

  get '/test' do
    'Hi there endpoint is active'
  end

  get '/subscriptions' do
    shopify_id = params['shopify_id']
    logger.debug params.inspect
    if shopify_id.nil?
      return [400, @default_headers, JSON.generate(error: 'shopify_id required')]
    end
    data = Customer.joins(:subscriptions)
      .find_by(shopify_customer_id: shopify_id, status: 'ACTIVE')
      .subscriptions
      .where(status: 'ACTIVE', shopify_product_id: Subscription::CURRENT_PRODUCTS.pluck(:id))
      .map{|sub| [sub, sub.orders]}
    output = data.map{|i| transform_subscriptions(*i)}
    [200, @default_headers, output.to_json]
  end

  get '/subscription/:subscription_id/sizes' do |subscription_id|
    sub = Subscription.find subscription_id
    #sub = Subscription.limit(200).sample
    [404, @default_headers, {error: 'subscription not found'}.to_json] if sub.nil?
    [200, @default_headers, sub.sizes.to_json]
  end

  post '/subscriptions' do
    json = JSON.parse request.body.read
    shopify_id = json['shopify_id']
    if shopify_id.nil?
      return [400, JSON.generate({error: 'shopify_id required'})]
    end
    data = Customer.joins(:subscriptions)
      .find_by(shopify_customer_id: shopify_id, status: 'ACTIVE')
      .subscriptions
      .map{|sub| [sub, sub.orders]}
    output = data.map{|i| transform_subscriptions(*i)}
    [200, @default_headers, output.to_json]
  end

  get '/subscription/:subscription_id' do |subscription_id|
    subscription = Subscription.find(subscription_id)
    [200, @default_headers, subscription.to_json]
  end

  put '/subscription/:subscription_id/sizes' do |subscription_id|
    # body parsing and validation
    begin
      json = JSON.parse request.body.read
      sizes = json.select{|key, _| SubLineItem::SIZE_PROPERTIES.include? key}
      logger.debug "sizes: #{sizes}"
    rescue Exception => e
      logger.error e.inspect
      return [400, @default_headers, {error: e}.to_json]
    end
    line_items = sizes.map do |item, size|
      SubLineItem.find_or_initialize_by(
        subscription_id: subscription_id,
        name: item,
        value: size,
      )
    end
    logger.debug "line items: #{line_items.inspect}"
    unless line_items.all?(&:valid?)
      error = {
        error: 'Invalid sizes',
        details: line_items.errors.collect.flatten
      }
      return [400, @default_headers, error.to_json]
    end
    # Recharge and cache update
    begin
      body = {id: subscription_id, properties: line_items.map{|i| {name: i.name, value: i.value}}}
      #res = RechargeAPI.put("/subscriptions/#{subscription_id}", {body: body_json})
      queued = Subscription.async(:recharge_update, body)
      raise 'Error updating sizes. Please try again later.' unless queued
      line_items.each(&:save!)
    rescue Exception => e
      logger.error e.inspect
      return [500, @default_headers, {error: e}.to_json]
    end
    [200, @default_headers, body.to_json]
  end

  put '/subscription/:subscription_id' do |subscription_id|
    subscription = Subscription.find_by(subscription_id: subscription_id)
    if subscription.nil?
      return [400, @default_headers, {error: 'subscription not found'}.to_json]
    end
    begin
      json = JSON.parse request.body.read
      matching_keys = (subscription.API_MAP.pluck(:remote_keys) & json.keys)
      subscription.update(json.select { |k, _| matching_keys.include? k })
    rescue
      return [400, @default_headers, {error: 'invalid payload data'}.to_json]
    end
    begin
      res = Subscription.async(:recharge_update, subscription.as_recharge)
      raise 'Error processing subscription change. Please try again later.' unless res
      subscription.save
    rescue StandardError => e
      logger.error e.inspect
      return [500, @default_headers, {error: e}.to_json]
    end
    output = {subscription: subscription}
    [200, @default_headers, output.to_json]
  end

  post '/subscription/:subscription_id/skip' do |subscription_id|
    sub = Subscription.find subscription_id
    return [400, @default_headers, {error: 'subscription not found'}.to_json] if sub.nil?
    skip_res = sub.skip
    queue_res = Subscription.async :skip!, subscription_id
    # FIXME: currently does not allow skipping prepaid subscriptions
    if queue_res
      [200, @default_headers, {skipped: skip_res, subscription: sub.as_recharge}.to_json]
    else
      [500, @default_headers, {error: 'error processing skip'}.to_json]
    end
  end

  # demo endpoints for customers

  get '/customers' do
    customers = params.empty? ? Customer.all : Customer.where(params)
    output = customers.map(&:as_recharge).to_json
    [200, @default_headers, output]
  end

  get '/customers/:customer_id' do |customer_id|
    customer = Customer.find(customer_id)
    customer.recharge_update!
    output = customer.as_recharge.to_json
    [200, @default_headers, output]
  end

  put '/customer/:customer_id' do |customer_id|
    json = JSON.parse request.body
    json['customer_id'] = customer_id
    res = Customer.async.update_recharge(json)
    customer = Customer.from_recharge json
    if res && customer.errors.empty?
      [200, @default_headers, customer.as_recharge.to_json]
    else
      error = {
        error: 'invalid customer data',
        details: customer.errors
      }
      [400, @default_headers, error.to_json]
    end
  end

  put '/subscription_switch' do
    puts 'Received stuff'
    puts params.inspect
    puts '----------'
    myjson = params  
    
    puts "recharge_change_header = #{@recharge_change_header}"

    #myjson = JSON.parse(request.body.read)
    myjson['recharge_change_header'] = @recharge_change_header
    puts myjson.inspect
    my_action = myjson['action']
    if my_action == 'switch_product'
      Resque.enqueue(SubscriptionSwitch, myjson)
    else
      puts "Can't switch product, action must be switch product not #{my_action}"
    end

  end

  get '/skippable_subscriptions' do
    shopify_id = params['shopify_id']
    logger.debug params.inspect
    if shopify_id.nil?
      return [400, @default_headers, JSON.generate(error: 'shopify_id required')]
    end
    next_charge_sql = 'next_charge_scheduled_at > ? AND next_charge_scheduled_at < ?'
    data = Customer.joins(:subscriptions)
      .find_by(shopify_customer_id: shopify_id, status: 'ACTIVE')
      .subscriptions
      .where({
        status: 'ACTIVE',
        shopify_product_id: Subscription::SKIPPABLE_PRODUCTS.pluck(:id),
      })
      .where(next_charge_sql, Date.today.beginning_of_month, Date.today.end_of_month)
    output = data.map do |sub|
      {
        subscription_id: sub.subscription_id,
        shopify_product_title: sub.product_title,
        shopify_product_id: sub.shopify_product_id,
      }
    end
    [200, @default_headers, output.to_json]
  end


  class SubscriptionSwitch
    extend ResqueHelper
    @queue = "switch_product"
    def self.perform(params)
      #puts params.inspect
      Resque.logger = Logger.new("#{Dir.getwd}/logs/resque.log")
      
      #{"action"=>"switch_product", "subscription_id"=>"8672750", "product_id"=>"8204555081"}
      subscription_id = params['subscription_id']
      product_id = params['product_id']
      puts "We are working on subscription #{subscription_id}"
      Resque.logger.info("We are working on subscription #{subscription_id}")

      temp_hash = provide_alt_products(product_id)
      puts temp_hash
      Resque.logger.info("new product info for subscription #{subscription_id} is #{temp_hash}")

      recharge_change_header = params['recharge_change_header']
      puts recharge_change_header
      body = temp_hash.to_json
      
      puts body
      #puts "Got here hoser"

      
      
      my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{subscription_id}", :headers => recharge_change_header, :body => body, :timeout => 80)
      puts my_update_sub.inspect
      Resque.logger.info(my_update_sub.inspect)
  
      
      update_success = false
      if my_update_sub.code == 200
        update_success = true
        puts "****** Hooray We have no errors **********"
        Resque.logger.info("****** Hooray We have no errors **********")
      else
        puts "We were not able to update the subscription"
        Resque.logger.info("We were not able to update the subscription")
      end


    end
  end



  private

  def transform_subscriptions(sub, orders)
    logger.debug "subscription: #{sub.inspect}"
    { 
      shopify_product_id: sub.shopify_product_id.to_i,
      subscription_id: sub.subscription_id.to_i,
      product_title: sub.product_title,
      next_charge: sub.next_charge_scheduled_at.try{|time| time.strftime('%Y-%m-%d')},
      charge_date: sub.next_charge_scheduled_at.try{|time| time.strftime('%Y-%m-%d')},
      sizes: sub.line_items
        .select {|l| l.size_property?}
        .map{|p| [p['name'], p['value']]}
        .to_h,
      prepaid: sub.prepaid?,
      prepaid_shipping_at: sub.shipping_at.try{|time| time.strftime('%Y-%m-%d')},
    }
  end

end
