require 'dotenv'
Dotenv.load
require 'sinatra/base'
require 'json'
require 'httparty'
require 'resque'
require 'shopify_api'
require 'active_support/core_ext'
require 'sinatra/activerecord'

require_relative 'models/all'
require_relative 'recharge_api'
require_relative 'logging'
require_relative 'resque_helper'
require_relative 'resque_change_sizes'

class EllieAdmin < Sinatra::Base
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
    @app_url = 'www.ellieactivesportshelp.com'
    @default_headers = { 'Content-Type' => 'application/json' }
    @recharge_token = ENV['RECHARGE_ACCESS_TOKEN']
    @recharge_change_header = {
      'X-Recharge-Access-Token' => @recharge_token,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    super
  end

  get '/hello' do
    'Hello, success, thanks for installing me!'
  end

  get '/config' do
    configs = Config.all.map{|c| [c.key, c.val]}.to_h
    [200, @default_headers, configs.to_json]
  end

  get '/config/:id' do |id|
    [200, @default_headers, Config[id].to_json]
  end

  post 'config/:id' do |id|
    Config[id] = JSON.parse request.body.read
  end

  put 'config/:id' do |id|
    Config[id] = JSON.parse request.body.read
  end

  delete 'config/:id' do |id|
    Config[id].delete
  end

  error do
    [500, @default_headers, {error: env['sinatra.error'].message}.to_json]
  end

end
