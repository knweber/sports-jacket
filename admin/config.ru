#require 'rack'
require 'rack/contrib'
require 'active_record'
require 'rack/cors'
require_relative 'app.rb'
require_relative 'controllers/product_tag_controller'

app = Rack::Builder.app do
  use Rack::CommonLogger, Logger.new(STDOUT)
  use Rack::Cors, debug: true do
    allow do
      origins '*'
      resource '*', headers: :any, methods: :any
    end
  end
  use Rack::TryStatic,
    root: File.dirname(__FILE__) + '/public',
    index: 'index.html'
  run EllieAdmin
  #run ProductTagController
end

run app
#run EllieAdmin
