require 'dotenv'
Dotenv.load
require 'sinatra/base'
require 'json'
require 'httparty'
require 'resque'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'ostruct'

require_relative '../models/all'
require_relative '../lib/recharge_api'
require_relative '../lib/logging'
require_relative '../lib/shopify_init.rb'

require_relative 'controllers/product_tag_controller'

class EllieAdmin < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  include Logging

  PAGE_LIMIT = 250

  configure do
    enable :logging
    set :server, :puma
    set :dump_errors, true
    set :static, true
    #set :protection, :except => [:json_csrf]

    mime_type :application_javascript, 'application/javascript'
    mime_type :application_json, 'application/json'
  end

  def initialize
    @tokens = {}
    @key = ENV['SHOPIFY_API_KEY']
    @secret = ENV['SHOPIFY_SHARED_SECRET']
    @app_url = 'www.ellieactivesportshelp.com'
    @json_headers = { 'Content-Type' => 'application/json' }
    @recharge_token = ENV['RECHARGE_ACCESS_TOKEN']
    @recharge_change_header = {
      'X-Recharge-Access-Token' => @recharge_token,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    super
  end

  get '/hello' do
    'Hello, welcome to Ellie Admin!'
  end

  get '/' do
    [200, {}, template('index', {})]
  end

  get '/config' do
    configs = Config.all.map{|c| [c.key, c.val]}.to_h
    [200, @json_headers, configs.to_json]
  end

  get '/config/:id' do |id|
    [200, @json_headers, Config[id].to_json]
  end

  post '/config/:id' do |id|
    Config[id] = JSON.parse request.body.read
  end

  put '/config/:id' do |id|
    Config[id] = JSON.parse request.body.read
  end

  delete '/config/:id' do |id|
    Config[id].delete
  end

  get '/product_tags/new' do
    product_tag = ProductTag.new
    vars = {
      product_tag: product_tag,
      themes: ShopifyAPI::Theme.all.map{|t| [t.id, t.name]}.to_h,
      products: Product.all.pluck(:shopify_id, :title).to_h,
    }
    [200, {}, template('/product_tags/new', vars)]
  end

  get '/product_tags' do
    vars = {
      product_tags: ProductTag.all,
      themes: ShopifyAPI::Theme.all.map{|t| [t.id, t.name]}.to_h,
      products: Product.all.pluck(:shopify_id, :title).to_h,
    }
    [200, {}, template('product_tags/index', vars)]
  end

  get '/product_tags.json' do
    [200, @json_headers, ProductTag.all.to_json]
  end

  get '/product_tags/:id' do |id|
    product_tag = ProductTag.find(id)
    theme = ShopifyAPI::Theme.find(product_tag.theme_id)
    vars = {
      product_tag: product_tag,
      theme_name: theme.name,
      product_name: Product.find(product_tag.product_id).name
    }
    [200, {}, template('/product_tags/view', vars)]
  end

  get '/product_tags/:id/edit' do |id|
    product_tag = ProductTag.find(id)
    theme = ShopifyAPI::Theme.find(product_tag.theme_id)
    vars = {
      product_tag: product_tag,
      themes: theme.name,
      products: Product.all.pluck(:shopify_id, :title).to_h,
    }
    [200, {}, template('/product_tags/edit', vars)]
  end

  get '/product_tags/:id.json' do |id|
    [200, @json_headers, ProductTag.find(id).to_json]
  end

  delete '/product_tags/:id' do |id|
    ProductTag.find(id).delete
    200
  end

  put '/product_tags/:id' do |id|
    ProductTag.find(id).update! params
    200
  end

  post '/product_tags' do
    product = ProductTag.create! params
    [201, @json_headers, product.to_json]
  end

  delete '/product_tags/:id' do |id|
    ProductTag.find(id).delete
    200
  end

  error ActiveRecord::RecordNotFound do
    details = env['sinatra.error'].message
    [404, @json_headers, {error: 'Record not found', details: details}.to_json]
  end

  error do
    [500, @json_headers, {error: env['sinatra.error'].message}.to_json]
  end

  private

  def template(name, vars, safe_level = 0, trim_mode = '>')
    namespace = OpenStruct.new(vars).instance_eval { binding }
    File.open("#{File.dirname __FILE__}/views/#{name}.html.erb", 'r') do |file|
      template = ERB.new(file.read, safe_level, trim_mode)
      template.result(namespace)
    end
  end
end
