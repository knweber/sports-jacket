require_relative '../lib/init'
Dotenv.load
require_relative 'ellie_listener.rb'
run EllieListener
