# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

OrderStatus.create(:name => 'New')
OrderStatus.create(:name => 'In Process')
OrderStatus.create(:name => 'Cancelled')
OrderStatus.create(:name => 'Complete')
OrderStatus.create(:name => 'Reconciled')

Affiliate.find_or_create_by_name('Other')

p = PriceGroup.new(:name => Settings.price_group.name.base, :is_internal => true, :display_order => 1)
p.save(:validate => false)
p = PriceGroup.new(:name => Settings.price_group.name.cancer_center, :is_internal => true, :display_order => 2)
p.save(:validate => false)
p = PriceGroup.new(:name => Settings.price_group.name.external, :is_internal => false, :display_order => 3)
p.save(:validate => false)
