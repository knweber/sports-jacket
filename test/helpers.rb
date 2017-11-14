# returns a customer safe to test on
def test_customer
  Customer.find_by shopify_customer_id: '5053796050'
end

# returns a subscription that is safe to test on
def test_subscription
  test_customer.subscriptions.where(status: 'ACTIVE').sample
end

def select_random(klass)
  klass.find(klass.all.ids.sample)
end
