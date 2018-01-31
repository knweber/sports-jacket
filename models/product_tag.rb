class ProductTag < ActiveRecord::Base

  # the options this method takes are:
  # * :time - a valid datetime string / object
  # * :theme_id - the theme the product tag is associated with
  def self.active(options = {})
    puts "Calling ProductTag::active time zone: #{Time.zone.inspect}, options: #{options.inspect}"
    theme_id = options[:theme_id] || Config[:current_theme_id].to_s
    time = options[:time] || Time.zone.now
    sql = "
      (theme_id is null OR theme_id = ?)
      AND (active_start is null OR active_start < ?)
      AND (active_end is null OR active_end > ?)
    "
    where(sql, theme_id, time, time)
  end

  # the options this method takes are:
  # * :time - a valid datetime string / object
  # * :theme_id - the theme the product tag is associated with
  def active?(options = {})
    self.class.active(options).ids.include? id
  end
end
