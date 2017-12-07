require 'active_record'
require_relative 'config'

class ProductTag < ActiveRecord::Base
  def self.active
    sql = "
      (theme_id = null OR theme_id = ?)
      AND (active_start = null OR active_start < ?)
      AND (active_end = null OR active_end > ?)
    "
    where(sql, Config[:current_theme_id], Time.now, Time.now)
  end

  def active?
    [
      theme_id.nil? || theme_id == Config[:current_theme_id],
      active_start.nil? || active_start < Time.now,
      active_end.nil? || active_end > Time.now,
    ].all?
  end
end
