require_relative '../src/ellie_listener.rb'

# elliestaging shopify config
Config['shopify'] = {
  shop_name: 'elliestaging',
  api_key: 'aa89e2e4aca8715770a8c5d3149abb98',
  api_shared_secret: 'e6057ee983e9b4c9fafc2363f9864ac9',
  api_password: '0bda7a26942001b0a5728c2e810d4b9f'
}

# these values came from elliestaging on 11/28
Config['rollover'] = {
  new_theme_id: 8050671648,
  current_collection_id: 19622428704,
  new_current_collection_product_ids: [409385271328, 9007888773],
  past_collection_id: 19623280672,
  new_past_collection_product_ids: [9003059781],
  new_alternate_product_id: 409382027296,
  new_exclusives_collection_id: 19622494240,
}

# Ellie production configs below

# ellieactive rollover for 12/17
#Config['shopify'] = {
  #shop_name: 'ellieactive',
  #api_key: '59221049ec03849642bf3f1a00911f49',
  #api_shared_secret: '31bba2a69efdd8cb77e5c6e3e6e9d3b6',
  #api_password: 'fe30edfd8709de2c51a2250261568c09'
#}

#Config['rollover'] = {
  #new_theme_id: 316735506,
  #current_collection_id: 1935540242,
  #new_current_collection_product_ids: [69026938898, 69036316306],
  #past_collection_id: 1933967378,
  #new_past_collection_product_ids: [10016265938]
  #new_alternate_product_id: 44383469586,
  #new_exclusives_collection_id: 2036793362,
#}
