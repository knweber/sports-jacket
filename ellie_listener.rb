#ellie_listener.rb
#recharge_listener.rb
require 'dotenv'
Dotenv.load
require 'sinatra/base'
require 'json'
require 'httparty'
require 'resque'
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'

require './models/model'

class EllieListener < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  configure do

    enable :logging
    set :server, :puma
    #set :protection, :except => [:json_csrf]


    mime_type :application_javascript, 'application/javascript'
    mime_type :application_json, 'application/json'
  end

  def initialize
    @recharge_access_token = ENV['RECHARGE_STAGING_ACCESS_TOKEN']
    @get_header =  {
      "X-Recharge-Access-Token" => "#{@recharge_access_token}"
    }
    @change_header = {
      "X-Recharge-Access-Token" => "#{@recharge_access_token}",
      "Accept" => "application/json",
      "Content-Type" =>"application/json"
    }
    @tokens = {}
    @key = ENV['SHOPIFY_API_KEY']
    @secret = ENV['SHOPIFY_SHARED_SECRET'] 
    @app_url = "ec2-174-129-48-228.compute-1.amazonaws.com"
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


end
