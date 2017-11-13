require 'active_record'
require 'active_record/base'
<<<<<<< HEAD
#require 'safe_attributes'

class Subscription < ActiveRecord::Base
=======
require 'safe_attributes'

class Subscription < ActiveRecord::Base
  has_many :orders, primary_key: :subscription_id, foreign_key: :subscription_id
>>>>>>> 057f34848aeed32b449f7af81b3785a76ac8e766
  belongs_to :customer, primary_key: :customer_id
  has_many :line_items, {
    class_name: "SubLineItem",
    primary_key: :subscription_id,
  }
<<<<<<< HEAD
  has_many :order_line_items, {
    primary_key: :subscription_id,
    class_name: 'OrderLineItemsFixed'
  }
  has_many :orders, {
    primary_key: :subscription_id,
    #foreign_key: :subscription_id,
    through: :order_line_items,
  }
  PREPAID_PRODUCTS = [
    {id: "23729012754", title: "3 MONTHS"},
=======
  PREPAID_PRODUCTS = [
    {id: "9421067602", title: "3 MONTHS"},
>>>>>>> 057f34848aeed32b449f7af81b3785a76ac8e766
    {id: "8204584905", title: "6 Month Box"},
    {id: "9109818066", title: "VIP 3 Month Box"},
    {id: "9175678162", title: "VIP 3 Monthly Box"},
  ]
  def prepaid?
    PREPAID_PRODUCTS.map{|p| p[:id]}.include? shopify_product_id
  end

  def shipping_at
    next_order = orders.where(status: 'QUEUED')
      .where('scheduled_at > ?', Date.today)
      .order(:scheduled_at)
      .first
    return next_order.scheduled_at unless next_order.nil?
  end
end

class SubLineItem < ActiveRecord::Base
  belongs_to :subscription, primary_key: :subscription_id
  SIZE_PROPERTIES = ['leggings', 'tops', 'sports-jacket', 'sports-bra']
  def size_property?
    SIZE_PROPERTIES.include? name
  end
end

class UpdateLineItem < ActiveRecord::Base
end

class Charge < ActiveRecord::Base
  has_one :shipping_address, {
    primary_key: :charge_id,
    class_name: 'ChargeShippingAddress',
  }
  has_many :shipping_lines, {
    primary_key: :charge_id,
    class_name: 'ChargeShippingLine',
  }
end

class ChargeShippingAddress < ActiveRecord::Base
  self.table_name = 'charges_shipping_address'
  belongs_to :charge, primary_key: :charge_id
end

class ChargeShippingLine < ActiveRecord::Base
  self.table_name = 'charges_shipping_lines'
  belongs_to :charge, primary_key: :charge_id
end

class OrderLineItemsFixed < ActiveRecord::Base
  self.table_name = 'order_line_items_fixed'
  belongs_to :subscription, primary_key: :subscription_id
  belongs_to :order, primary_key: :order_id
end

class Order < ActiveRecord::Base
  # The column 'type' uses a reserved word in active record. Calling this class
  # results in:
  #
  # ActiveRecord::SubclassNotFound: The single-table inheritance mechanism
  # failed to locate the subclass: 'CHECKOUT'. This error is raised because the
  # column 'type' is reserved for storing the class in case of inheritance.
  # Please rename this column if you didn't intend it to be used for storing the
  # inheritance class or overwrite Order.inheritance_column to use another
  # column for that information.
  #
  # See: https://stackoverflow.com/questions/17879024/activerecordsubclassnotfound-the-single-table-inheritance-mechanism-failed-to
  #self.inheritance_column = nil

  has_one :line_items, {
    class_name: "OrderLineItemsFixed",
    primary_key: :order_id,
  }
  has_one :subscription, through: :line_items, primary_key: :order_id

  def subscription_id
    line_items.subscription_id
  end
end

class Customer < ActiveRecord::Base
  has_many :subscriptions, primary_key: :customer_id
  has_many :orders, through: :subscriptions
  # This safe attributes line is due to an actvive record error on the Customer
  # table. The table contains a column named `hash` which collides with the
  # ActiveRecord::Base#hash method. For mor info see:
  # https://github.com/rails/rails/issues/18338
  #include SafeAttributes::Base
  #bad_attribute_names :hash
end