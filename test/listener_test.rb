ENV['RACK_ENV'] = 'test'

require_relative '../src/ellie_listener.rb'
require_relative '../src/logging.rb'
require 'test/unit'
require 'rack/test'

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

  def test_it_responds_to_subscriptions_get
    get '/subscriptions'
    assert last_response.ok?
  end

  def test_customer_index_returns_max_results
    get '/customers'
    assert last_response.ok?
    customer_list = JSON.parse last_response.body
    assert customer_list.length <= 250
  end

  def test_customers_match_recharge_api
    customer = Customer.last
    file = File.open "#{File.dirname __FILE__}/../docs/customer_example.json", 'r'
    example_json = file.read
    logger.debug example_json
    example = JSON.parse example_json
    get "/customers/#{customer.customer_id}"
    logger.debug last_response.body
    response = JSON.parse last_response.body
    logger.debug response
    assert example['customer'].keys == response.keys
  end

end
