require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require 'resque/tasks'
require_relative 'get_ellie_info'

desc "Get all subscriptions"
task :get_all_subscriptions do
    DetermineInfo::InfoGetter.new.count_subscriptions
end

desc "update line item properties in subscriptions"
task :update_line_items do
    DetermineInfo::InfoGetter.new.update_line_item_properties
end


desc "delete all tables for cleanup"
task :delete_all_tables do
    DetermineInfo::InfoGetter.new.delete_tables2
end



desc "testing customer_yesterday"
task :testing_customer_yesterday_pull do
    DetermineInfo::InfoGetter.new.testing_customer_yesterday_pull
end


desc "test update justin subscription properties"
task :update_test_justin_sub do
    DetermineInfo::InfoGetter.new.test_update_justin_sub
end



desc "update all subscriptions with sports-jacket size from tops"
task :update_sports_jacket do
    DetermineInfo::InfoGetter.new.update_subscription_sports_jacket 
end

desc "testing line item properties held in subscriptions"
task :testing_line_items do
    DetermineInfo::InfoGetter.new.sub_testing
end


desc "retrieve a test subscription via sub id"
task :retrieve_subscription do
    DetermineInfo::InfoGetter.new.retrieve_sub
end

#count_charges
desc "insert all charges in ReCharge"
task :insert_charges do
    DetermineInfo::InfoGetter.new.insert_charges_into_db
end

desc "insert all orders in Recharge to DB"
task :insert_orders do
    DetermineInfo::InfoGetter.new.insert_orders_into_db
end



desc "insert all customers in Recharge to DB"
task :insert_customers do
    DetermineInfo::InfoGetter.new.insert_customers_into_db
end


desc "insert all addresses in Recharge to DB"
task :insert_addresses do
    DetermineInfo::InfoGetter.new.insert_addresses_into_db
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
