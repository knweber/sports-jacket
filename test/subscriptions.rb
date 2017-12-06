ENV['RACK_ENV'] = 'test'

require_relative '../api/ellie_listener.rb'
require_relative '../lib/logging.rb'
require_relative 'helpers'
require 'test/unit'
require 'rack/test'

puts "redis url: #{ENV['REDIS_URL']}"
puts "database url: #{ENV['DATABASE_URL']}"
puts "recharge api: #{ENV['RECHARGE_ACCESS_TOKEN']}"

class SubscriptionTest < Test::Unit::TestCase
  include Logging

  def test_it_does_not_skip_prepaid_subscriptions
  end

  def test_it_only_skips_subscriptions_scheduled_to_be_charged_this_month
  end

end
