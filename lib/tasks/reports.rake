# frozen_string_literal: true

namespace :reports do
  desc "Gives report for concatenated price rules"
  task concatenated_price_rules: :environment do
    policies = {}
    PricePolicy.current.group_by { |p| [p.product_id, p.price_group_id] }.each { |k, ps| policies[k] = ps if ps.count > 1 }
    policies.each do |info, overlapping_policies|
      product = Product.find(info.first)
      price_group = PriceGroup.find(info.last)
      puts "Product: #{product.name} (#{product.facility.name}), Price Group: #{price_group.name}"
      puts "Policies = #{overlapping_policies.map(&:id).join(', ')}"
      puts "-----------------------------------"
    end
    puts "No overlapping policies" if policies.empty?
  end
end
