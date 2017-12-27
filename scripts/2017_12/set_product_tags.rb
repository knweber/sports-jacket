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
  ProductTag.create({
    product_id: id,
    tag: tag,
    theme_id: '8050671648',
  })
end

PREPAID_PRODUCTS.each {|p| create_product_tag p[:id], 'prepaid'}
CURRENT_PRODUCTS.each {|p| create_product_tag p[:id], 'current'}
SKIPPABLE_PRODUCTS.each {|p| create_product_tag p[:id], 'skippable'}
