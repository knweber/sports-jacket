module Rollover
  def run!
    rollover_config = Config['rollover']
    shopify = Shopify.new(Config['shopify'])
    past_collection_id = rollover_config['past_collection_id']
    current_collection_id = rollover_config['current_collection_id']
    # TODO: get these datapoints
    new_product_ids = rollover_config['new_current_collection_product_ids']
    new_past_collection_product_ids = rollover_config['new_past_collection_product_ids']

    res = shopify.get("/collects.json?collection_id=#{current_collection_id}")
    unless res.ok?
      raise "unable to get current collection items. Response code: #{res.code}"
    end
    current_collects = res.parsed_response['collects']
    current_product_ids = current_collects.map {|collect| collect['product_id']}

    # delete current products from current collection
    current_collects.each do |collect|
      shopify.delete("/collect/#{collect['id']}.json")
    end

    # construct all the new collect association objects to be created from both current and
    # new products
    new_collects = []
    new_collects << (current_product_ids & new_past_collection_product_ids).map do |product_id|
      {
        product_id: product_id,
        collection_id: past_collection_id,
      }
    end
    new_collects << new_product_ids.map do |product_id|
      {
        product_id: product_id,
        collection_id: current_collection_id,
      }
    end

    # post new collect associations to shopify
    new_collects.each do |new_collect|
      res = shopify.post("/collects.json", data: { collect: new_collect })
      unless res.ok?
        raise "Unable to create collect for product: #{product_id} in collection: #{past_collection_id}"
      end
    end

    # set new theme
    theme_data = {
      id: new_theme_id,
      roll: 'main',
      published: true,
    }
    shopify.put("/themes/#{new_theme_id}.json", data: {theme: theme_data})
  end

end
