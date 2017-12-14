require 'active_record'
require 'active_record/base'

module ApplicationRecord

  def active_changes
    attributes.select{|k, _| changed.include? k}
  end

end

