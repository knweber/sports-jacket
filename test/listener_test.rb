ENV['RACK_ENV'] = 'test'

require_relative '../src/ellie_listener.rb'
require_relative '../src/logging.rb'
require_relative 'helpers'
require 'test/unit'
require 'rack/test'

puts "redis url: #{ENV['REDIS_URL']}"
puts "database url: #{ENV['DATABASE_URL']}"
puts "recharge api: #{ENV['RECHARGE_ACCESS_TOKEN']}"

class ListenerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Logging

  def app
    EllieListener
  end

  def test_it_says_hello_world
    get '/hello'
    assert last_response.ok?
    assert !last_response.body.empty?
  end

  def test_test_customer_exists
    logger.debug "test_customer: #{test_customer.inspect}"
    assert_not_nil test_customer
  end

  def test_it_responds_to_subscriptions_get
    get '/subscriptions'
    assert last_response.ok?
    assert JSON.parse(last_response.body).length <= 250
  end

  def test_it_updates_a_subscription
    sub = test_subscription
    put "/subscriptions/#{sub.subscription_id}", shopify_id: 'silly value'
    assert last_response.ok?
    json = JSON.parse(last_response.body)
    # check that we returned a 'preview' of what the updated object will look
    # like after sent to rechrge successfully
    assert_equal json['shopify_id'], 'silly_value'
    # check that unsent values remain the same
    assert_equal json['price'], sub.price, 'updated price value did not match expected value'
    assert_equal json['properties'], sub.as_recharge.properties, 'updated properties did not match expected value'
  end

  def test_it_retrieves_a_subscription
    f = File.open("#{File.dirname __FILE__}/../docs/subscription_example.json")
    example_json = JSON.parse f.read
    sub = test_subscription
    get "/subscriptions/#{sub.subscription_id}"
    assert last_response.ok?
    json = JSON.parse(last_response.body)
    assert_equal example_json['subscription'].keys.sort, json.keys.sort, 'output did not match Recharge API'
  end

  def test_it_retrieves_a_customer
    f = File.open("#{File.dirname __FILE__}/../docs/customer_example.json")
    example_json = JSON.parse f.read
    get "/customers/#{test_customer.customer_id}"
    assert last_response.ok?
    json = JSON.parse(last_response.body)
    assert_equal example_json['customer'].keys.sort, json.keys.sort, 'output did not match recharge API'
  end

  def test_customer_index_returns_max_results
    get '/customers'
    assert last_response.ok?
    customer_list = JSON.parse last_response.body
    assert customer_list.length <= 250
  end

  def test_customers_match_recharge_api
    file = File.open "#{File.dirname __FILE__}/../docs/customer_example.json", 'r'
    example_json = file.read
    #logger.debug example_json
    example = JSON.parse example_json
    get "/customers/#{test_customer.customer_id}"
    #logger.debug last_response.body
    response = JSON.parse last_response.body
    #logger.debug response
    assert example['customer'].keys == response.keys
  end

end
