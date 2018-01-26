require_relative '../config/environment.rb'
require_relative 'app.rb'

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
end

run app
#run EllieAdmin
