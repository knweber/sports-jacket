class Config < ActiveRecord::Base
  self.table_name = :config
  self.primary_key = :key

  def self.[](key)
    find(key).try(:val)
  end

  def self.[]=(key, value)
    config = find_or_initialize_by(primary_key => key)
    config.val = value
    config.save if config.changed?
  end

  def self.to_h
    all.map{|r| [r[primary_key], r.val]}.to_h
  end
end
