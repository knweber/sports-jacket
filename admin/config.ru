#require 'rack'
require 'rack/contrib'
require_relative 'app.rb'

app = Rack::Builder.app do
  use Rack::CommonLogger, Logger.new(STDOUT)
  use Rack::TryStatic,
    root: File.dirname(__FILE__) + '/public',
    index: 'index.html'
  run EllieAdmin
end

run app
#run EllieAdmin
