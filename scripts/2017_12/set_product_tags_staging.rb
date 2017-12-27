require_relative 'pry_context'

# products that get shipped more than once per billing cycle
PREPAID_PRODUCTS = [
  { id: '9421067602', title: '3 MONTHS' },
  { id: '9109818066', title: 'VIP 3 Month Box' },
  { id: '9175678162', title: 'VIP 3 Monthly Box' },
].freeze

# for changing sizes
CURRENT_PRODUCTS = [
  { id: '8204555081', title: 'Monthly Box' },
  { id: '9175678162', title: 'VIP 3 Monthly Box' },
  { id: '10870327954', title: 'Alternate Monthly Box/ Fit to Be Seen' },
  { id: '23729012754', title: 'NEW 3 MONTHS' },
  { id: '9109818066', title: 'VIP 3 Month Box' },
  { id: '10016265938', title: 'Ellie 3- Pack: ' },
  { id: '10870682450', title: 'Fit to Be Seen Ellie 3- Pack' },
  { id: '44383469586', title: 'Go Time' },
  { id: '52386037778', title: 'Go Time - 3 Item' },
  { id: '78548729874', title: 'Go Time - 3 Item  Auto renew' },
  { id: '78480408594', title: 'Go Time - 5 Item' },
  { id: '78681669650', title: 'Go Time - 5 Item  Auto renew' },
  { id: '69026938898', title: 'Power Moves - 3 Item' },
  { id: '78541520914', title: 'Power Moves - 3 Item  Auto renew' },
  { id: '69026316306', title: 'Power Moves - 5 Item' },
  { id: '78657093650', title: 'Power Moves - 5 item  Auto renew' },
].freeze

# for skips/alternates
SKIPPABLE_PRODUCTS = [
  { id: '8204555081', title: 'Monthly Box' },
  { id: '10016265938', title: 'Ellie 3- Pack: ' },
  { id: '69026938898', title: 'Power Moves - 3 Item' },
  { id: '69026316306', title: 'Power Moves - 5 Item' },
].freeze

def create_product_tag(id, tag)
  ProductTag.create(
    product_id: id,
    tag: tag,
    theme_id: '8050671648',
  )
end

# Power Moves 5 item
create_product_tag 9007888773, 'current'
create_product_tag 9007888773, 'skippable'
create_product_tag 9007888773, 'switchable'

# Power Moves 3 item
create_product_tag 409385271328, 'current'
create_product_tag 409385271328, 'skippable'
create_product_tag 409385271328, 'switchable'

# Go Time 5 item
create_product_tag 409382027296, 'current'

# Go Time 3 item
create_product_tag 417063993376, 'current'

# 3 MONTHS
create_product_tag 7814019397, 'prepaid'
create_product_tag 7814019397, 'current'

# VIP 3 months
create_product_tag 7462179397, 'prepaid'
create_product_tag 7462179397, 'current'

# VIP 3 monthly
create_product_tag 7462180165, 'prepaid'
create_product_tag 7462180165, 'current'

# fit to be seen
create_product_tag 409384353824, 'current'

# fit to be seen 3 pack
create_product_tag 409384321056, 'current'

# cozy collection
create_product_tag 7462175365, 'current'

# cozy collection 3 pack
create_product_tag 9003059781, 'current'
