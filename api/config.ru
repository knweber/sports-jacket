require_relative 'config/environment'
Dotenv.load
require_relative 'ellie_listener.rb'
run EllieListener
