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
    @app_url = 'ec2-174-129-48-228.compute-1.amazonaws.com'
    @default_headers = { 'Content-Type' => 'application/json' }
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
        code: code}

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
  end

  get '/subscriptions/meta' do 
    shopify_id = params['shopify_id']
    logger.debug params.inspect
    if shopify_id.nil?
      return [400, @default_headers, JSON.generate(error: 'shopify_id required')]
    end
    data = Customer.joins(:subscriptions)
      .find_by(shopify_customer_id: shopify_id, status: 'ACTIVE')
      .subscriptions
      .map{|sub| [sub, sub.orders]}
    output = data.map{|i| transform_subscriptions(*i)}
    [200, @default_headers, output.to_json]
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

  put '/subscription/:subscription_id/size' do |subscription_id|
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
      return [400, @default_headers, {error: 'subscription_id not found'}.to_json]
    end
    begin
      json = JSON.parse request.body.read
      # NOTE: For future usability purposes we should probably just map the json
      # field names 1:1. Or at least a subset of them.
      body = {
        'product_title' => json['alt_product_title'],
        'shopify_product_id' => json['alt_product_id'],
        'shopify_variant_id' => json['alt_product_variant_id'],
        'sku' => json['alt_product_sku'],
      }
    rescue
      return [400, @default_headers, {error: 'invalid payload data'}.to_json]
    end
    begin
      body_json = body.to_json
      logger.debug "sending to recharge: #{body_json}"
      res = RechargeAPI.put("/subscriptions/#{subscription_id}", body: body_json)
      logger.debug('request options: ' + res.request.options.inspect)
      logger.debug('recharge response: ' + res.parsed_response.inspect)
      logger.debug 'raw response: ' + res.body
      raise 'Error processing subscription change. Please try again later.' unless res.success?
      body.each{|k,v| subscription[k] ||= v }
      subscription.save
    rescue Exception => e
      logger.error e.inspect
      return [500, @default_headers, {error: e}.to_json]
    end
    output = {subscription: subscription}
    [200, @default_headers, output.to_json]
  end

  post '/subscription/:subscription_id/skip' do |subscription_id|
  end

  # demo endpoints for customers

  get '/customers' do
    customers = params.empty? ? Customer.all : Customer.where(params)
    output = customers.map(&:as_recharge).to_json
    [200, @default_headers, output]
  end

  get '/customers/:customer_id' do |customer_id|
    customer = Customer.find(customer_id)
    output = customer.as_recharge.to_json
    [200, @default_headers, output]
  end

  put '/customer/:customer_id' do |customer_id|
    customer = Customer.find(customer_id)
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
