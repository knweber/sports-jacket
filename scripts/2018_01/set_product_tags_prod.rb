#!/bin/ruby

require_relative '../pry_context'

# fit and fierce
ProductTag.find_or_create_by(product_id: 91235975186, tag: 'current', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91236171794, tag: 'current', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91235975186, tag: 'skippable', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91236171794, tag: 'skippable', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91235975186, tag: 'switchable', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91236171794, tag: 'switchable', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))

# alt product, modern muse
ProductTag.find_or_create_by(product_id: 91236368402, tag: 'current', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
ProductTag.find_or_create_by(product_id: 91236466706, tag: 'current', active_start: Time.new(2018, 1, 1, 0, 0, 0, '+08:00'))
