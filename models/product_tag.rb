require_relative '../lib/init'
require 'active_record/base'
require 'active_support/all'
require_relative 'config'

class ProductTag < ActiveRecord::Base

  # the options this method takes are:
  # * :time - a valid datetime string / object
  # * :theme_id - the theme the product tag is associated with
  def self.active(options = {})
    puts "Calling ProductTag::active time zone: #{Time.zone.inspect}, options: #{options.inspect}"
    theme_id = options[:theme_id] || Config[:current_theme_id].to_s
    time = options[:time] || Time.zone.now
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
    current_theme_id = options[:theme_id] || Config[:current_theme_id]
    now = options[:time] || Time.zone.now
    puts "now: #{now.inspect}, current theme: #{current_theme_id}"
    [
      theme_id.nil? || theme_id == current_theme_id,
      active_start.nil? || active_start < now,
      active_end.nil? || active_end > now,
    ].all?
  end
end
