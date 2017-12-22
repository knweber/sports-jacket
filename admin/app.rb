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
require_relative '../lib/logging'
require_relative '../lib/init'

require_relative 'controllers/product_tag_controller'

class EllieAdmin < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  include Logging

  PAGE_LIMIT = 250

  configure do
    enable :logging, :methlod_override
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
    @app_url = 'www.ellieactivetesting.com'
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
    template 'index'
  end

  get '/config' do
    configs = Config.all
    puts "Configs #{configs.inspect}"
    configs_out = configs.map{|c| [c.key, c.val]}.to_h
    puts "Configs out: #{configs_out.inspect}"
    template('config/index', configs: configs_out)
  end

  get '/config/new' do
    config = Config.new
    template('config/new', key: config.key, val: config.val)
  end

  get '/config/:key/edit' do |key|
    config = Config.find_by(key: key)
    template('config/edit', config: config)
  end

  get '/config.json' do
    configs = Config.all.map{|c| [c.key, c.val]}.to_h
    [200, @json_headers, configs.to_json]
  end

  get '/config/:key.json' do |key|
    [200, @json_headers, Config[key].to_json]
  end

  post 'config/:key' do |key|
    Config.find_or_initialize_by(key: key)
      .update(filter_params(Config, params))
    redirect '/config', 302
  end

  post '/config/:key.json' do |key|
    Config[key] = JSON.parse request.body.read
  end

  put '/config/:key.json' do |key|
    Config[key] = JSON.parse request.body.read
  end

  delete '/config/:key' do |key|
    Config[key].delete!
    redirect '/config', 302
  end

  delete '/config/:key.json' do |key|
    Config[key].delete!
    [200, @json_headers, { success: "Record deleted." }.to_json]
  end

  get '/product_tags/new' do
    product_tag = ProductTag.new
    vars = {
      product_tag: product_tag,
      themes: ShopifyAPI::Theme.all.map{|t| [t.id, t.name]}.to_h,
      products: Product.all.pluck(:shopify_id, :title).to_h,
    }
    [200, {}, template('product_tags/new', vars)]
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
    [200, {}, template('product_tags/view', vars)]
  end

  get '/product_tags/:id/edit' do |id|
    product_tag = ProductTag.find(id)
    vars = {
      product_tag: product_tag,
      themes: ShopifyAPI::Theme.all.sort_by(&:updated_at),
      products: Product.all.pluck(:shopify_id, :title).to_h,
    }
    [200, {}, template('product_tags/edit', vars)]
  end

  get '/product_tags/:id.json' do |id|
    [200, @json_headers, ProductTag.find(id).to_json]
  end

  delete '/product_tags/:id' do |id|
    ProductTag.delete id
    redirect '/product_tags', 302
  end

  delete '/product_tags/:id.json' do |id|
    ProductTag.delete id
    [200, @json_headers, { success: 'Record deleted.' }]
  end

  put '/product_tags/:id' do |id|
    ProductTag.update(id, filter_params(ProductTag, params))
    redirect '/product_tags', 302
  end

  put '/product_tags/:id.json' do |id|
    json = JSON.parse request.body.read
    product_tag = ProductTag.find(id).update!(json)
    [200, @json_headers, product_tag.to_json]
  end

  post '/product_tags' do
    ProductTag.create!(filter_params(ProductTag, params))
    redirect '/product_tags', 302
  end

  post '/product_tags.json' do
    product_tag = ProductTag.create!(filter_params(ProductTag, params))
    [201, @json_headers, product_tag.to_json]
  end

  get '/webhooks/rollover' do
    date = Date.current.strftime '%Y-%m-%d'
    # set the config
    new_config = Config["rollover_config_#{date}"]
    unless config.nil?
      new_config.each do |key, val|
        Config[key] = val
      end
    end
    # update the subscription products
    sub_products = Config["rollover_subscription_products_#{date}"]
    unless sub_products.nil?
      Resque.enqueue_to :rollover, 'Rollover', :subscription_products, sub_products
    end
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

  def template(name, vars = {}, safe_level = 0, trim_mode = '>')
    namespace = OpenStruct.new(vars).instance_eval { binding }
    File.open("#{File.dirname __FILE__}/views/#{name}.html.erb", 'r') do |file|
      template = ERB.new(file.read, safe_level, trim_mode)
      template.result(namespace)
    end
  end

  def filter_params(klass, params)
    params.select do |k, _|
      klass.attributes.keys.include? k
    end
  end
end
