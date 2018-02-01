require_relative 'resque_helper'

class ChangeSizes

  extend ResqueHelper
  @queue = 'change_sizes'
  def self.perform(subscription_id, new_sizes)
    Resque.logger = Logger.new("#{Dir.getwd}/logs/size_change_resque.log")
    sub = Subscription.find subscription_id
    Resque.logger.info(sub.inspect)
    sub.sizes = new_sizes
    Resque.logger.info("Now sizes are #{sub.sizes}.inspect")
    #body = {properties: sub.raw_line_item_propertie}
    res = Recharge::Subscription.update(sub.subscription_id, properties: sub.raw_line_item_properties)
    sub.save! if res
    #puts "recharge response to change sizes: #{res.response}"
    #Resque.logger.info("recharge sent back from changing sizes #{res.response}")
    #new_props = res.parsed_response['subscription']['properties'
    #Resque.logger.info("New sub properties --> #{res.parsed_response['subscription']['properties']}")
    #puts "new sub props: #{new_props}"
    #Subscription.find(subscription_id).update(raw_line_item_properties: new_props)
    puts 'Sizes updated!'
    Resque.enqueue(SendEmailToCustomer, subscription_id)
    Resque.enqueue(SendEmailToCS, subscription_id) if !res
  end
end
