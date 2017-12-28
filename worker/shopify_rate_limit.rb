class BucketLimit
  attr_reader :redis
  attr_accessor :key

  DEFAULT_LIMIT = 20

  def initialize(bucket_id, redis_url = nil, key_prefix = 'bucket_limit')
    url ||= ENV['REDIS_URL']
    @redis = Redis.new url: url
    @key = "#{key_prefix}_#{bucket_id}"
  end

  def set(limit)
    redis.set key limit
  end

  def get
    redis.get(key).to_i
  end

  def wait(limit = DEFAULT_LIMIT, &block)
    current = get
    Kernel.sleep(limit - current) if (limit - current) > 0
    yield block
  end
end
