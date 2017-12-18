root = "#{Dir.getwd}"

#environment 'production'

#activate_control_app "tcp://127.0.0.1:9293"
bind "tcp://0.0.0.0:9292"
rackup "#{root}/config.ru"
daemonize false
#stdout_redirect '/u/apps/lolcat/log/stdout', '/u/apps/lolcat/log/stderr'
#stdout_redirect '/home/floyd/sports-jacket/logs/stdout', '/home/floyd/sports-jacket/logs/stderr', true

