require 'active_record'
require_relative 'config'

class ProductTag < ActiveRecord::Base

  # the options this method takes are:
  # * :time - a valid datetime string / object
  # * :theme_id - the theme the product tag is associated with
  def self.active(options = {})
    theme_id = options[:theme_id] || Config[:current_theme_id]
    time = options[:time] || Time.now
    sql = "
      (theme_id = null OR theme_id = ?)
      AND (active_start = null OR active_start < ?)
      AND (active_end = null OR active_end > ?)
    "
    where(sql, theme_id, time, time)
  end

  # the options this method takes are:
  # * :time - a valid datetime string / object
  # * :theme_id - the theme the product tag is associated with
  def active?(options = {})
    theme_id = options[:theme_id] || Config[:current_theme_id]
    time = options[:time] || Time.now
    [
      theme_id.nil? || theme_id == Config[:current_theme_id],
      active_start.nil? || active_start < Time.now,
      active_end.nil? || active_end > Time.now,
    ].all?
  end
end
