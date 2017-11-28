root = "#{Dir.getwd}"

environment 'production'




#bind "unix://#{root}/tmp/puma.sock"
#bind "tcp://localhost:9292"
bind "tcp://0.0.0.0:9292"
#bind "tcp://0.0.0.0:8080"
pidfile "#{root}/tmp/pids/puma.pid"



activate_control_app "tcp://127.0.0.1:9293"
#activate_control_app 'unix:///#{root}/tmp/pids/pumactl.sock'
#bind "unix://#{root}/tmp/puma.sock"
#pidfile "#{root}/tmp/pids/puma.pid"
rackup "#{root}/config.ru"
state_path "#{root}/tmp/puma.state"
daemonize true

