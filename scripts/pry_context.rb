require 'dotenv'
Dotenv.load
require 'active_record'
require 'shopify_api'
require 'active_support/core_ext'
#require 'recharge_api'
Dir[File.dirname(__FILE__) + '/../lib/*.rb'].each do |file|
  require_relative file
end
require_relative '../models/all'
require_relative '../test/helpers.rb'

ActiveRecord::Base.establish_connection ENV['DATABASE_URL']
Resque.redis = Redis.new(url: ENV['REDIS_URL'])
