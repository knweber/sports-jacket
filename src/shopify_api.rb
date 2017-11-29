class Shopify

  def self.async(config, method, path, options)
    Shopify.new(config).send(method, path, options)
  end

  def initialize(config)
    @domain = config['shop_name'] + ".myshopify.com"
    @base_url = "#{config['api_key']}:#{config['api_password']}@#{@domain}/admin"
    @default_options = {
      verify: false,
    }
  end

  def get(path, options = {})
    opt = @default_options.merge options
    url = "https://#{@base_url}#{path}"
    pp opt, url
    res = HTTParty.get(url, opt)
    #puts "Status: #{res.status}"
    res
  end

  def post(path, options = {})
    opt = @default_options.merge options
    HTTParty.post("https://#{@base_url}#{path}", opt)
  end

  def put(path, options = {})
    opt = @default_options.merge options
    HTTParty.put("https://#{@base_url}#{path}", opt)
  end

  def patch(path, options = {})
    opt = @default_options.merge options
    HTTParty.patch("https://#{@base_url}#{path}", opt)
  end

  def delete(path, options = {})
    opt = @default_options.merge options
    HTTParty.delete("https://#{@base_url}#{path}", opt)
  end
end
