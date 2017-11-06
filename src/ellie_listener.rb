require 'dotenv'
Dotenv.load
require 'sinatra/base'
require 'json'
require 'httparty'
require 'resque'
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'

require_relative 'models/model'
require_relative 'recharge_api'
require_relative 'logging'

class EllieListener < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  include Logging

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
    @app_url = "ec2-174-129-48-228.compute-1.amazonaws.com"
    @default_headers = {"Content-Type" => "application/json"}
    super
  end

  get '/install' do
    shop = "elliestaging.myshopify.com"
    scopes = "read_orders, write_orders, read_products, read_customers, write_customers"

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

    if not (hmac == digest)
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
        return [500, "Something went wrong."]
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
    "Hello, success, thanks for installing me!"
  end

  get '/test' do
    "Hi there endpoint is active"
  end

  get '/subscriptions' do 
    shopify_id = params['shopify_id']
    logger.debug params.inspect
    if shopify_id.nil?
      return [400, JSON.generate({error: 'shopify_id required'})]
    end
    #subscriptions = Recharge.subscriptions_by_shopify_id shopify_id
    data = Customer.joins(:subscriptions)
      .where(shopify_customer_id: shopify_id)
      .collect(&:subscriptions)
      .flatten
      .map{|sub| [sub, sub.orders]}
    output = data.map{|i| transform_subscriptions(*i)}
    [200, @default_headers, JSON.generate(output)]
  end

  #post '/subscriptions' do
    #json = JSON.parse request.body.read
    #shopify_id = json['shopify_id']
    #unless shopify_id.instance_of? Integer
      #return [400, JSON.generate({error: 'shopify_id required'})]
    #end
    #subscriptions = Recharge.subscriptions_by_shopify_id shopify_id
    #collection = subscriptions.map{|s| [s, s.orders]}
    #output = subscriptions.map{|i| transform_subscriptions(*i)}
    #[200, JSON.generate(output)]
  #end

  #private

  def transform_subscriptions(sub, orders)
    logger.debug "subscription: #{sub.inspect}"
    { 
      shopify_product_id: sub.shopify_product_id.to_i,
      subscription_id: sub.subscription_id.to_i,
      product_title: sub.product_title,
      next_charge: sub.next_charge_scheduled_at.strftime('%Y-%m-%d'),
      charge_date: sub['next_charge_scheduled_at'].strftime('%Y-%m-%d'),
      sizes: sub.line_items
        .select {|l| l.size_property?}
        .map{|p| [p['name'], p['value']]}
        .to_h,
      prepaid: sub.prepaid?,
      prepaid_shipping_at: sub.prepaid? ? sub.shipping_at : nil,
    }
  end

end
