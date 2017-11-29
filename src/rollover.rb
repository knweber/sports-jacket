module Rollover
  def self.run!
    outcome = []
    puts 'Starting rollover...'
    rollover_config = Config['rollover']
    shopify = Shopify.new(Config['shopify'])

    puts 'Getting current collection...'
    current_collects = get_collects_from_collection(shopify, rollover_config['current_collection_id'])
    current_product_ids = current_collects.map {|collect| collect['product_id']}

    puts 'Clearing current collection...'
    outcome << clear_collection(shopify, rollover_config['current_collection_id'])

    puts 'Posting products to past collection...'
    (current_product_ids & rollover_config['new_past_collection_product_ids']).each do |product_id|
      outcome << add_product_to_collection(shopify, product_id, rollover_config['past_collection_id'])
    end
    puts 'Posting new current collection products...'
    rollover_config['new_current_collection_product_ids'].each do |product_id|
      outcome << add_product_to_collection(shopify, product_id, rollover_config['current_collection_id'])
    end

    puts 'Setting new theme...'
    outcome << set_new_theme(shopify, rollover_config['new_theme_id'])

    outcome.all?
  end

  def self.get_collects_from_collection(shopify, collection_id)
    res = shopify.get("/collects.json?collection_id=#{collection_id}")
    unless res.success?
      puts
      puts res.code
      puts res.parsed_response
      raise "unable to get current collection items. Response code: #{res.code}"
    end
    res.parsed_response['collects']
  end

  def self.clear_collection(shopify, collection_id)
    outcome = []
    collects = get_collects_from_collection(shopify, collection_id)
    collects.each do |collect|
      res = shopify.delete("/collects/#{collect['id']}.json")
      outcome << res.success?
      next if res.success?
      puts
      puts res.code
      puts res.parsed_response
      puts "Unable to remove current collect #{collect.inspect}"
    end
    outcome.all?
  end

  def self.add_product_to_collection(shopify, product_id, collection_id)
    new_collect = {
      product_id: product_id,
      collection_id: collection_id
    }
    res = shopify.post('/collects.json', body: { collect: new_collect }.to_json)
    unless res.success?
      puts
      puts res.code
      puts res.parsed_response
      puts "Unable to create collect association #{new_collect.inspect}"
    end
    res.success?
  end

  def self.set_new_theme(shopify, new_theme_id)
    theme_data = {
      id: new_theme_id,
      role: 'main',
    }
    res = shopify.put("/themes/#{new_theme_id}.json", body: {theme: theme_data}.to_json)
    unless res.success?
      puts
      puts res.code
      puts res.parsed_response
      #puts "Unable to set new theme id: #{new_theme_id}"
    end
    res.success?
  end

end
