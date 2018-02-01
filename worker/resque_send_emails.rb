require_relative 'resque_helper'
require 'sendgrid-ruby'

class SendEmailToCustomer
  extend ResqueHelper
  include Logging
  include SendGrid

  @queue = 'send_customer_confirmation'
  def self.perform(subscription_updated_id)
    Resque.logger = Logger.new("#{Dir.getwd}/logs/send_emails_resque.log")

    updated_subscription = SubscriptionsUpdated.find(subscription_updated_id)
    subscription = Subscription.find(updated_subscription.subscription_id)
    customer = Customer.find(subscription.customer_id)
    # address_id = subscription.address_id

    begin
      from = Email.new(email: ENV['no-reply@ellie.com'], name: 'Ellie')
      subject = "Confirmation of subscription change"
      to = Email.new(email: customer.email)
      
      content = Content.new(type: 'text/plain', value: 'Your information has been updated. Thanks for shopping at ellie.com!')
      mail = Mail.new(from, subject, to, content)
      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'], host: 'https://api.sendgrid.com')

      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.headers
    rescue Exception => e
      Resque.logger.error(e.inspect)
    end
    puts "** Sent! **"
  end
end

class SendEmailToCS
  # Need to get Recharge stuff
  extend ResqueHelper
  include Logging
  include SendGrid

  @queue = 'send_cs_error_email'
  def self.perform(subscription_updated_id)
    updated_subscription = SubscriptionsUpdated.find(subscription_updated_id)
    subscription = Subscription.find(updated_subscription.subscription_id)
    customer = Customer.find(subscription.customer_id)
    address_id = subscription.address_id
    prod_title = subscription.product_title

    begin
      from = Email.new(email: ENV['no-reply@ellie.com'], name: 'Ellie')
      subject = "Subscription update error"
      to = Email.new(email: 'help@ellie.com')

      content = Content.new(type: 'text/plain', value: "Subscription update error \n
      Customer ID: #{customer.customer_id} \n
      Customer email: #{customer.email} \n
      Subscription ID: #{subscription.id} \n
      Product title: #{prod_title}
      Address ID: #{address_id}")

      mail = Mail.new(from, subject, to, content)
      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'], host: 'https://api.sendgrid.com')

      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.headers

    rescue Exception => e
      Resque.logger.error(e.inspect)
    end
    puts "Email sent to customer service"
  end
end
