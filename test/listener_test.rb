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

end
