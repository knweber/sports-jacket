require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'



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



desc "testing justin subscription update"
task :testing_justin do
    DetermineInfo::InfoGetter.new.testing_update_justin
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
