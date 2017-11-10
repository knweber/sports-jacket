require 'dotenv'
Dotenv.load
require 'redis'
require 'resque'
Resque.redis = Redis.new(url: ENV['REDIS_URL'])
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require 'resque/tasks'

require_relative 'src/get_ellie_info'
require_relative 'src/models/model'

Resque.logger =
  if ENV['production']
    Logger.new STDOUT, level: Logger::INFO
  else
    Logger.new STDOUT, level: Logger::DEBUG
  end

desc "do full or partial pull of customers and add to DB"
task :customer_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_customers(*args)
end

desc "do full or partial pull of charge table and associated tables and add to DB"
task :charge_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_charges(*args)
end

desc "do full or partial pull of order table and associated tables and add to DB"
task :order_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_orders(*args)
end

desc "do full or partial pull of subscription table and associated tables and add to DB"
task :subscription_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_subscriptions(*args)
end
