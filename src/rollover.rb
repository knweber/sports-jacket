module Rollover
  def self.run!
    puts 'Starting rollover...'
    rollover_config = Config['rollover']
    shopify = Shopify.new(Config['shopify'])
    past_collection_id = rollover_config['past_collection_id']
    current_collection_id = rollover_config['current_collection_id']
    # TODO: get these datapoints
    new_product_ids = rollover_config['new_current_collection_product_ids']
    new_past_collection_product_ids = rollover_config['new_past_collection_product_ids']
    new_theme_id = rollover_config['new_theme_id']

    puts 'Getting current collection...'
    res = shopify.get("/collects.json?collection_id=#{current_collection_id}")
    unless res.ok?
      puts res.code
      puts res.parsed_response
      #raise "unable to get current collection items. Response code: #{res.code}"
    end
    current_collects = res.parsed_response['collects']
    current_product_ids = current_collects.map {|collect| collect['product_id']}

    puts 'Clearing current collection...'
    current_collects.each do |collect|
      shopify.delete("/collect/#{collect['id']}.json")
    end

    puts 'Building new collections'
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

    puts 'Posting new collection to shopify...'
    new_collects.each do |new_collect|
      res = shopify.post("/collects.json", data: { collect: new_collect })
      unless res.ok?
        puts res.code
        puts res.parsed_response
        #raise "Unable to create collect association #{new_collect.inspect}"
      end
    end

    puts 'Sessing new theme...'
    theme_data = {
      id: new_theme_id,
      roll: 'main',
      published: true,
    }
    res = shopify.put("/themes/#{new_theme_id}.json", data: {theme: theme_data})
    unless res.ok?
      puts res.code
      puts res.parsed_response
      #raise "Unable to set new theme id: #{new_theme_id}"
    end
    true
  end

end
