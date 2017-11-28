require 'dotenv'
Dotenv.load

require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require 'resque/tasks'
require_relative 'ellie_listener'


require_relative 'get_ellie_info'



desc "set up subscription_update table for processing"
task :setup_subscription_update do |t|
    DetermineInfo::InfoGetter.new.update_three_months_subs 
end


desc "process the subscription_update table to update three months subscriptions with new info"
task :process_subscription_update do |t|
    DetermineInfo::InfoGetter.new.process_three_month_subs

end

desc "do full or partial pull of customers and add to DB"
task :customer_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_customers(*args)
end

desc "do full or partial pull of charge table and associated tables and add to DB"
task :charge_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_charges(*args)
end

desc "do full or partial pull of order table and associated tables and add to DB"
task :order_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_orders(*args)
end

desc "do full or partial pull of subscription table and associated tables and add to DB"
task :subscription_pull, [:args] do |t, args|
    DetermineInfo::InfoGetter.new.handle_subscriptions(*args)
end