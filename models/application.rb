require 'active_record/base'
require 'active_support'

module ApplicationRecord
  extend ActiveSupport::Concern

  included do
  end

  def active_changes
    attributes.select{|k, _| changed.include? k}
  end

  class_methods do
  end

end

