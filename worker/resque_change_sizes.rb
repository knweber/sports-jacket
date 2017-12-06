require 'resque'
require_relative '../lib/recharge_api'

class ChangeSizes

  extend ResqueHelper
  @queue = 'change_sizes'
  def self.perform(subscription_id, new_sizes)
    Resque.logger = Logger.new("#{Dir.getwd}/logs/size_change_resque.log")
    sub = Subscription.find subscription_id
    Resque.logger.info(sub.inspect)
    sub.sizes = new_sizes
    Resque.logger.info("Now sizes are #{sub.sizes}.inspect")
    body = {properties: sub.raw_line_item_properties}
    res = RechargeAPI.put("/subscriptions/#{sub.subscription_id}", body: body.to_json)
    puts "recharge response to change sizes: #{res.response}"
    Resque.logger.info("recharge sent back from changing sizes #{res.response}")
    new_props = res.parsed_response['subscription']['properties']
    Resque.logger.info("New sub properties --> #{res.parsed_response['subscription']['properties']}")
    puts "new sub props: #{new_props}"
    Subscription.find(subscription_id).update(raw_line_item_properties: new_props)
  end
end
