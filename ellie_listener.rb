#ellie_listener.rb
#recharge_listener.rb
require 'dotenv'

require 'sinatra/base'
require 'json'
require 'httparty'


require "resque"
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'

require './models/model'

class EllieListener < Sinatra::Base
    register Sinatra::ActiveRecordExtension
  
  configure do
  
    enable :logging
    set :server, :puma
    Dotenv.load
    $logger = Logger.new('logs/common.log','weekly')
    $logger.level = Logger::INFO
      
    #set :protection, :except => [:json_csrf]
    
    
    mime_type :application_javascript, 'application/javascript'
    mime_type :application_json, 'application/json'
  end

  def initialize
    
    @key = ENV['SHOPIFY_API_KEY']
    @secret = ENV['SHOPIFY_SHARED_SECRET'] 
    @app_url = "388fcd78.ngrok.io"
    @tokens = {}

    @recharge_access_token = ENV['RECHARGE_ACCESS_TOKEN']
    @my_get_header =  {
              "X-Recharge-Access-Token" => "#{@recharge_access_token}"
          }
    @my_change_charge_header = {
              "X-Recharge-Access-Token" => "#{@recharge_access_token}",
              "Accept" => "application/json",
              "Content-Type" =>"application/json"
          }


    super
  end

  get '/install' do
    shop = "ellieactive.myshopify.com"
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

  post '/customer_info' do
    #$logger.info params.inspect
    customer_id = params['shopify_id']
    
    puts params.inspect
    puts customer_id
    customer_info = Customer.where("shopify_customer_id = ?", customer_id).first
    #puts customer_info.inspect
    local_customer_id = customer_info['customer_id']
    my_customer_info_return = Array.new

    subscription_info = Subscription.where("customer_id = ?", local_customer_id)
    subscription_info.each do |mysubinfo|
      #stuff to return to shopify page
      product_title = mysubinfo['product_title']
      next_charge = mysubinfo['next_charge_scheduled_at']
      subscription_id = mysubinfo['subscription_id']
      sub_properties = SubLineItem.where("subscription_id = ?", subscription_id)

      temp_array = []
      my_valid_properties = ['leggings', 'sports-bra', 'tops']
      sub_properties.each do |mysub|
        puts mysub.inspect
        if my_valid_properties.include? mysub.name
          puts "value --> #{mysub.value}" 
          temp_hash = {"name" => mysub.name, "value" => mysub.value}
          temp_array << temp_hash
        end
      end
      my_customer_info_return.push({ "subscription_product" => product_title, "next_charge" => next_charge, "properties" => temp_array }) 
    end

    #my_customer_info_return = [{"subscription_product" => product_title, "next_charge" => next_charge, "properties" => temp_array} ]
    puts my_customer_info_return
    my_customer_info_return = my_customer_info_return.to_json
    puts my_customer_info_return

  end



end