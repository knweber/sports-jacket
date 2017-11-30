require_relative 'util'

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

    puts 'Setting new alternate product...'
    outcome << set_alternate_product(shopify, rollover_config['new_alternate_product_id'])

    puts 'Setting new ellie_exclusives'
    exclusives_handle = 'ellie-exclusives'
    current_exclusives = shopify.get('/custom_collections.json', query: { handle: exclusives_handle })
      .parsed_response['custom_collections'].try(:first)
    if current_exclusives.nil?
      puts 'Error: could not find current exclusives collection'
    else
      set_collection_handle(shopify, current_exclusives['id'], RandomGenerator.string(10))
      set_collection_handle(shopify, rollover_config['new_exclusives_collection_id'], exclusives_handle)
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
      puts "Unable to set new theme id: #{new_theme_id}"
    end
    res.success?
  end

  def self.set_alternate_product(shopify, product_id)
    outcomes = []
    alternate_handle = 'alternate-monthly-box'
    current_alternate_product = shopify.get("/products.json", query: { handle: alternate_handle })['product']
    if current_alternate_product.nil?
      puts 'could not find alternate product'
      outcomes << false
      #return false
    else
      old_alternate = {
        id: current_alternate_product['id'],
        handle: RandomGenerator.string(10),
      }
      old_alternate_res = shopify.put("/products/#{old_alternate[:id]}.json", body: {product: old_alternate}.to_json)
      outcomes << old_alternate_res.success?
      unless old_alternate_res.success?
        puts
        puts old_alternate_res.code
        puts old_alternate_res.parsed_response
        puts "Unable to set handle for old alternate product: #{old_alternate_res.inspect}"
      end
    end
    new_alternate = {
      id: product_id,
      handle: alternate_handle,
    }
    new_alternate_res = shopify.put("/products/#{new_alternate[:id]}.json", body: {product: new_alternate}.to_json)
    outcomes << new_alternate_res.success?
    unless new_alternate_res.success?
      puts
      puts new_alternate_res.code
      puts new_alternate_res.parsed_response
      puts "Unable to set handle for new alternate product: #{new_alternate_res.inspect}"
    end
    outcomes.all?
  end

  def self.set_collection_handle(shopify, collection_id, handle)
    data = { custom_collection: {
      id: collection_id,
      handle: handle
    } }
    res = shopify.put("/custom_collections/#{collection_id}.json", body: data.to_json)
    unless res.success?
      puts
      puts new_alternate_res.code
      puts new_alternate_res.parsed_response
      puts "Unable to set handle '#{handle}' for collection #{collection_id}"
    end
    res.success?
  end

end
