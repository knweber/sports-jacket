root = "#{Dir.getwd}"

environment ENV['RACK_ENV'] || 'development'

#activate_control_app "tcp://127.0.0.1:9293"
bind "tcp://0.0.0.0:9292"
rackup "#{root}/config.ru"
daemonize false
#stdout_redirect '/u/apps/lolcat/log/stdout', '/u/apps/lolcat/log/stderr'
#stdout_redirect '/home/floyd/sports-jacket/logs/stdout', '/home/floyd/sports-jacket/logs/stderr', true

on_worker_boot do |thread_id = nil|
  File.open('/tmp/test', 'w+') do |f|
    f.write "worker booting: #{thread_id.inspect}"
    f.write "woker boot timezone: #{Time.zone.inspect}"
  end
end
