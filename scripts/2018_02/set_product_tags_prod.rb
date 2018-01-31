#!/bin/ruby

require_relative '../pry_context'

month_start = Time.local(2018, 2)
month_end = month_start.end_of_month
base_tag = { active_start: month_start, active_end: month_end }

# sunset the old tags without an active_end
ProductTag.where(active_end: nil).update_all(active_end: month_start - 1.second)

# main: La Vie en Rose
main_3 = 138427301906
main_5 = 138427203602
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_3, tag: 'current'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_5, tag: 'current'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_3, tag: 'skippable'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_5, tag: 'skippable'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_3, tag: 'switchable'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_5, tag: 'switchable'))

# alt 1
alt1_3 = 138427596818
alt1_5 = 138427465746
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_3, tag: 'current'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt1_5, tag: 'current'))

# alt 2
alt2_3 = 138427793426
alt2_5 = 138427695122
ProductTag.find_or_create_by(base_tag.merge(product_id: alt2_3, tag: 'current'))
ProductTag.find_or_create_by(base_tag.merge(product_id: alt2_5, tag: 'current'))
