require 'pathname'
root = Pathname.new(File.dirname(__FILE__) + '..').cleanpath
puts "Running from #{root}"

environment 'production'

rackup "#{root}/config.ru"
bind "unix:/tmp/puma.sock"
bind "tcp://0.0.0.0:9292"
daemonize false
